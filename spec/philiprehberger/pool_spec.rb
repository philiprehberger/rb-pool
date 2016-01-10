# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::Pool do
  it 'has a version number' do
    expect(Philiprehberger::Pool::VERSION).not_to be_nil
  end

  describe Philiprehberger::Pool::ResourcePool do
    let(:counter) { [0] }
    let(:factory) do
      lambda {
        counter[0] += 1
        double("Resource#{counter[0]}", id: counter[0], close: nil)
      }
    end

    describe '#with' do
      it 'yields a resource and returns it to the pool' do
        pool = described_class.new(size: 2, &factory)
        yielded = nil

        pool.with { |r| yielded = r }

        expect(yielded).not_to be_nil
        expect(pool.stats[:available]).to eq(1)
        expect(pool.stats[:in_use]).to eq(0)
      end

      it 'returns the block result' do
        pool = described_class.new(size: 2, &factory)
        result = pool.with { |_r| 42 }
        expect(result).to eq(42)
      end

      it 'returns resource even if block raises' do
        pool = described_class.new(size: 2, &factory)

        expect do
          pool.with { |_r| raise 'boom' }
        end.to raise_error(RuntimeError, 'boom')

        expect(pool.stats[:available]).to eq(1)
        expect(pool.stats[:in_use]).to eq(0)
      end
    end

    describe 'pool size' do
      it 'does not exceed max size' do
        pool = described_class.new(size: 2, timeout: 0.1, &factory)
        pool.checkout
        pool.checkout

        expect(pool.stats[:size]).to eq(2)
        expect do
          pool.checkout(timeout: 0.1)
        end.to raise_error(Philiprehberger::Pool::TimeoutError)
      end
    end

    describe 'timeout' do
      it 'raises TimeoutError when pool is exhausted' do
        pool = described_class.new(size: 1, timeout: 0.1, &factory)
        pool.checkout

        expect do
          pool.checkout(timeout: 0.1)
        end.to raise_error(Philiprehberger::Pool::TimeoutError)
      end
    end

    describe 'lazy creation' do
      it 'creates objects on demand' do
        pool = described_class.new(size: 5, &factory)

        expect(pool.stats[:size]).to eq(0)

        pool.checkout
        expect(pool.stats[:size]).to eq(1)

        pool.checkout
        expect(pool.stats[:size]).to eq(2)
      end
    end

    describe '#stats' do
      it 'returns correct available and in_use counts' do
        pool = described_class.new(size: 3, &factory)

        r1 = pool.checkout
        pool.checkout

        expect(pool.stats[:size]).to eq(2)
        expect(pool.stats[:available]).to eq(0)
        expect(pool.stats[:in_use]).to eq(2)

        pool.checkin(r1)

        expect(pool.stats[:available]).to eq(1)
        expect(pool.stats[:in_use]).to eq(1)
      end
    end

    describe '#shutdown' do
      it 'rejects new checkouts after shutdown' do
        pool = described_class.new(size: 2, &factory)
        pool.shutdown

        expect(pool.shutdown?).to be true
        expect do
          pool.checkout
        end.to raise_error(Philiprehberger::Pool::ShutdownError)
      end

      it 'rejects with block after shutdown' do
        pool = described_class.new(size: 2, &factory)
        pool.shutdown

        expect do
          pool.with { |_r| nil }
        end.to raise_error(Philiprehberger::Pool::ShutdownError)
      end
    end

    describe 'health check' do
      it 'replaces bad resource with new one' do
        call_count = [0]
        health_proc = ->(resource) { resource.id != 1 }

        pool = described_class.new(size: 2, health_check: health_proc) do
          call_count[0] += 1
          double("Resource#{call_count[0]}", id: call_count[0], close: nil)
        end

        r1 = pool.checkout
        expect(r1.id).to eq(1)
        pool.checkin(r1)

        r2 = pool.checkout
        expect(r2.id).to eq(2)
      end
    end

    describe 'thread safety' do
      it 'handles concurrent checkouts' do
        pool = described_class.new(size: 5) do
          counter[0] += 1
          counter[0]
        end

        threads = Array.new(10) do
          Thread.new do
            pool.with do |_r|
              sleep(0.01)
            end
          end
        end

        expect { threads.each(&:join) }.not_to raise_error
        expect(pool.stats[:in_use]).to eq(0)
      end
    end

    describe 'idle timeout' do
      it 'evicts idle resources on checkout' do
        pool = described_class.new(size: 2, idle_timeout: 0.05, &factory)

        r = pool.checkout
        pool.checkin(r)

        sleep(0.1)

        r2 = pool.checkout
        expect(r2).not_to be_nil
      end
    end

    describe '.new convenience method' do
      it 'creates a ResourcePool via module method' do
        pool = Philiprehberger::Pool.new(size: 1) { 'resource' }
        expect(pool).to be_a(described_class)
      end
    end

    describe 'validation' do
      it 'requires a factory block' do
        expect { described_class.new(size: 1) }.to raise_error(ArgumentError)
      end

      it 'requires a positive size' do
        expect { described_class.new(size: 0) { 'x' } }.to raise_error(ArgumentError)
      end
    end
  end
end
