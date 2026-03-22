# frozen_string_literal: true
require 'spec_helper'
RSpec.describe Philiprehberger::Pool do
  let(:counter) { [0] }
  let(:pool) { described_class.new(size: 3, timeout: 2) { counter[0] += 1; counter[0].to_s } }

  after { pool.shutdown unless pool.shutdown? }

  describe '#checkout' do
    it 'yields a resource to the block' do
      pool.checkout do |resource|
        expect(resource).to eq('1')
      end
    end

    it 'returns the resource after block completes' do
      pool.checkout { |_r| nil }
      expect(pool.available).to eq(1)
    end

    it 'creates resources lazily' do
      expect(counter[0]).to eq(0)
      pool.checkout { |_r| nil }
      expect(counter[0]).to eq(1)
    end

    it 'reuses returned resources' do
      pool.checkout { |_r| nil }
      pool.checkout { |_r| nil }
      expect(counter[0]).to eq(1)
    end
  end

  describe '#with' do
    it 'is an alias for checkout' do
      pool.with do |resource|
        expect(resource).to eq('1')
      end
    end
  end

  describe '#checkin' do
    it 'returns resource to the pool' do
      resource = pool.checkout
      expect(pool.available).to eq(0)
      pool.checkin(resource)
      expect(pool.available).to eq(1)
    end
  end

  describe '#size' do
    it 'returns the configured pool size' do
      expect(pool.size).to eq(3)
    end
  end

  describe '#available' do
    it 'returns the number of available resources' do
      expect(pool.available).to eq(0)
      pool.checkout { |_r| nil }
      expect(pool.available).to eq(1)
    end
  end

  describe '#stats' do
    it 'returns pool statistics' do
      pool.checkout { |_r| nil }
      stats = pool.stats
      expect(stats[:size]).to eq(3)
      expect(stats[:created]).to eq(1)
      expect(stats[:available]).to eq(1)
      expect(stats[:in_use]).to eq(0)
    end

    it 'tracks in-use resources' do
      resource = pool.checkout
      stats = pool.stats
      expect(stats[:in_use]).to eq(1)
      pool.checkin(resource)
    end
  end

  describe '#shutdown' do
    it 'marks the pool as shut down' do
      pool.shutdown
      expect(pool).to be_shutdown
    end

    it 'closes resources that respond to close' do
      closeable = double('resource', close: nil)
      p = described_class.new(size: 1, timeout: 1) { closeable }
      p.checkout { |_r| nil }
      expect(closeable).to receive(:close)
      p.shutdown
    end

    it 'rejects new checkouts after shutdown' do
      pool.shutdown
      expect { pool.checkout { |_r| nil } }.to raise_error(described_class::PoolShutdownError)
    end
  end

  describe 'timeout' do
    it 'raises TimeoutError when pool is exhausted' do
      small_pool = described_class.new(size: 1, timeout: 0.1) { 'resource' }
      small_pool.checkout # don't checkin
      expect { small_pool.checkout }.to raise_error(described_class::TimeoutError)
      small_pool.shutdown
    end
  end

  describe 'health check' do
    it 'discards unhealthy resources' do
      calls = [0]
      healthy_pool = described_class.new(size: 2, timeout: 1, health_check: ->(r) { r != 'bad' }) do
        calls[0] += 1
        calls[0] == 1 ? 'bad' : 'good'
      end

      healthy_pool.checkout { |_r| nil }
      healthy_pool.checkout do |resource|
        expect(resource).to eq('good')
      end
      healthy_pool.shutdown
    end
  end

  describe 'thread safety' do
    it 'handles concurrent checkouts' do
      thread_pool = described_class.new(size: 5, timeout: 5) { Object.new }
      threads = 10.times.map do
        Thread.new do
          thread_pool.checkout { |_r| sleep(0.01) }
        end
      end
      threads.each(&:join)
      expect(thread_pool.stats[:created]).to be <= 5
      thread_pool.shutdown
    end
  end

  describe 'validation' do
    it 'requires a factory block' do
      expect { described_class.new(size: 1, timeout: 1) }.to raise_error(ArgumentError)
    end

    it 'requires a positive size' do
      expect { described_class.new(size: 0, timeout: 1) { 'x' } }.to raise_error(ArgumentError)
    end
  end
end
