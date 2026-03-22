# frozen_string_literal: true

require_relative 'pool/version'

module Philiprehberger
  class Pool
    class TimeoutError < StandardError; end
    class PoolShutdownError < StandardError; end

    attr_reader :size

    def initialize(size: 5, timeout: 5, health_check: nil, &factory)
      raise ArgumentError, 'a factory block is required' unless factory
      raise ArgumentError, 'size must be positive' unless size.positive?

      @size = size
      @timeout = timeout
      @health_check = health_check
      @factory = factory

      @mutex = Mutex.new
      @resource_available = ConditionVariable.new
      @pool = []
      @in_use = {}
      @created = 0
      @shutdown = false
    end

    def checkout(&block)
      raise PoolShutdownError, 'pool is shut down' if @shutdown

      resource = acquire_resource

      if block
        begin
          yield resource
        ensure
          checkin(resource)
        end
      else
        resource
      end
    end

    alias with checkout

    def checkin(resource)
      @mutex.synchronize do
        @in_use.delete(resource.object_id)
        @pool.push(resource) unless @shutdown
        @resource_available.signal
      end
    end

    def available
      @mutex.synchronize { @pool.length }
    end

    def in_use
      @mutex.synchronize { @in_use.length }
    end

    def stats
      @mutex.synchronize do
        {
          size: @size,
          created: @created,
          available: @pool.length,
          in_use: @in_use.length
        }
      end
    end

    def shutdown
      @mutex.synchronize do
        @shutdown = true
        @pool.each do |resource|
          resource.close if resource.respond_to?(:close)
        end
        @pool.clear
        @resource_available.broadcast
      end
    end

    def shutdown?
      @shutdown
    end

    private

    def acquire_resource
      deadline = Time.now + @timeout

      @mutex.synchronize do
        loop do
          raise PoolShutdownError, 'pool is shut down' if @shutdown

          resource = try_get_resource
          return resource if resource

          remaining = deadline - Time.now
          raise TimeoutError, "could not acquire resource within #{@timeout} seconds" if remaining <= 0

          @resource_available.wait(@mutex, remaining)
        end
      end
    end

    def try_get_resource
      while (resource = @pool.pop)
        if healthy?(resource)
          @in_use[resource.object_id] = resource
          return resource
        end

        @created -= 1
      end

      if @created < @size
        resource = @factory.call
        @created += 1
        @in_use[resource.object_id] = resource
        return resource
      end

      nil
    end

    def healthy?(resource)
      return true unless @health_check

      @health_check.call(resource)
    rescue StandardError
      false
    end
  end
end
