# philiprehberger-pool

[![Tests](https://github.com/philiprehberger/rb-pool/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-pool/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-pool.svg)](https://rubygems.org/gems/philiprehberger-pool)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-pool)](https://github.com/philiprehberger/rb-pool/commits/main)

Generic thread-safe object pool with idle timeout and health checks

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-pool"
```

Or install directly:

```bash
gem install philiprehberger-pool
```

## Usage

```ruby
require "philiprehberger/pool"

# Create a pool of database connections
pool = Philiprehberger::Pool.new(size: 5, timeout: 10) do
  SomeDatabase.connect(host: 'localhost')
end

# Automatic checkout/checkin with a block
pool.with do |conn|
  conn.query('SELECT 1')
end

# Manual checkout/checkin
conn = pool.checkout
begin
  conn.query('SELECT 1')
ensure
  pool.checkin(conn)
end
```

### Health Checks

```ruby
pool = Philiprehberger::Pool.new(
  size: 5,
  timeout: 10,
  health_check: ->(conn) { conn.ping }
) { SomeDatabase.connect }
```

### Idle Timeout

```ruby
pool = Philiprehberger::Pool.new(
  size: 5,
  idle_timeout: 60
) { SomeDatabase.connect }
```

### Pool Stats

```ruby
pool.stats
# => { size: 2, available: 1, in_use: 1, max: 5 }
```

### Pruning Idle Resources

```ruby
pool = Philiprehberger::Pool.new(size: 5, idle_timeout: 60) { TCPSocket.new("db.local", 5432) }

# Periodically reclaim idle handles without waiting for the next checkout
pruned = pool.prune_idle  # => count of resources evicted
```

### Draining Idle Resources

```ruby
require "philiprehberger/pool"

pool = Philiprehberger::Pool.new(size: 5) { TCPSocket.new("db.local", 5432) }

# Rotate connections after a config change
drained = pool.drain  # => closes idle connections, returns count
# New checkouts will create fresh connections
```

### Shutdown

```ruby
pool.shutdown
pool.shutdown? # => true
```

## API

### `Philiprehberger::Pool.new(size:, timeout: 5, idle_timeout: nil, health_check: nil, &factory)`

Creates a new resource pool.

| Parameter | Description |
|-----------|-------------|
| `size` | Maximum number of resources |
| `timeout` | Seconds to wait for a resource (default: 5) |
| `idle_timeout` | Seconds before idle resources are evicted (default: nil) |
| `health_check` | Lambda called with resource, must return truthy (default: nil) |
| `&factory` | Block that creates a new resource |

### Instance Methods

| Method | Description |
|--------|-------------|
| `#with { \|resource\| ... }` | Checkout, yield, and auto-checkin |
| `#checkout(timeout: nil)` | Manually check out a resource |
| `#checkin(resource)` | Return a resource to the pool |
| `#drain` | Remove and close idle resources, return count drained |
| `#stats` | Hash with `:size`, `:available`, `:in_use`, `:max` |
| `#size` | Configured maximum capacity |
| `#prune_idle` | Evict available resources past `idle_timeout`, return count |
| `#shutdown` | Close all resources, reject new checkouts |
| `#shutdown?` | Whether the pool has been shut down |

### Errors

| Error | Description |
|-------|-------------|
| `Pool::TimeoutError` | Checkout timed out waiting for a resource |
| `Pool::ShutdownError` | Operation attempted on a shut-down pool |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-pool)

🐛 [Report issues](https://github.com/philiprehberger/rb-pool/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-pool/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
