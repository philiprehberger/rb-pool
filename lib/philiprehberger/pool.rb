# frozen_string_literal: true

require 'timeout'
require 'set'
require_relative 'pool/version'

module Philiprehberger
  module Pool
    class Error < StandardError; end
    class TimeoutError < Error; end
    class ShutdownError < Error; end

    PoolEntry = Struct.new(:resource, :last_used, keyword_init: true)

    class ResourcePool
      def initialize(size:, timeout: 5, idle_timeout: nil, health_check: nil, &factory)
        raise ArgumentError, 'size must be positive' unless size.positive?
        raise ArgumentError, 'factory block is required' unless factory

        @size = size
        @timeout = timeout
        @idle_timeout = idle_timeout
        @health_check = health_check
        @factory = factory

        @mutex = Mutex.new
        @condition = ConditionVariable.new
        @available = []
        @created = 0
        @in_use = Set.new
        @shutdown = false
      end

      def with
        raise ShutdownError, 'pool is shut down' if @shutdown

        resource = checkout
        begin
          yield resource
        ensure
          checkin(resource)
        end
      end

      def checkout(timeout: nil)
        raise ShutdownError, 'pool is shut down' if @shutdown

        effective_timeout = timeout || @timeout
        deadline = Time.now + effective_timeout

        @mutex.synchronize do
          loop do
            raise ShutdownError, 'pool is shut down' if @shutdown

            # Try to get a valid resource from the available pool
            until @available.empty?
              entry = @available.pop

              if idle_expired?(entry)
                destroy_resource(entry.resource)
                next
              end

              if health_check_fails?(entry.resource)
                destroy_resource(entry.resource)
                next
              end

              @in_use.add(entry.resource)
              return entry.resource
            end

            # Create new resource if under capacity
            if @created < @size
              resource = create_resource
              @in_use.add(resource)
              return resource
            end

            # Wait for a resource to become available
            remaining = deadline - Time.now
            raise TimeoutError, "could not obtain resource within #{effective_timeout}s" if remaining <= 0

            @condition.wait(@mutex, remaining)
          end
        end
      end

      def checkin(resource)
        @mutex.synchronize do
          return unless @in_use.delete?(resource)

          if @shutdown
            destroy_resource(resource)
          else
            @available.push(PoolEntry.new(resource: resource, last_used: Time.now))
            @condition.signal
          end
        end
      end

      def stats
        @mutex.synchronize do
          { size: @created, available: @available.size, in_use: @in_use.size, max: @size }
        end
      end

      def size
        @mutex.synchronize { @size }
      end

      def prune_idle
        @mutex.synchronize do
          raise ShutdownError, 'pool is shut down' if @shutdown
          return 0 unless @idle_timeout

          now = Time.now
          expired, kept = @available.partition { |entry| (now - entry.last_used) > @idle_timeout }
          @available = kept
          expired.each { |entry| destroy_resource(entry.resource) }
          expired.size
        end
      end

      def shutdown
        @mutex.synchronize do
          @shutdown = true

          @available.each { |entry| destroy_resource(entry.resource) }
          @available.clear

          @in_use.each { |resource| destroy_resource(resource) }
          @in_use.clear

          @condition.broadcast
        end
      end

      def drain
        @mutex.synchronize do
          raise ShutdownError, 'pool is shut down' if @shutdown

          drained = @available.dup
          @available.clear
          @size -= drained.size
          drained.each do |entry|
            entry.resource.close if entry.resource.respond_to?(:close)
          end
          drained.size
        end
      end

      def shutdown?
        @shutdown
      end

      private

      def create_resource
        resource = @factory.call
        @created += 1
        resource
      end

      def destroy_resource(resource)
        resource.close if resource.respond_to?(:close)
        @created -= 1
      end

      def idle_expired?(entry)
        return false unless @idle_timeout

        (Time.now - entry.last_used) > @idle_timeout
      end

      def health_check_fails?(resource)
        return false unless @health_check

        !@health_check.call(resource)
      rescue StandardError
        true
      end
    end

    def self.new(...)
      ResourcePool.new(...)
    end
  end
end
