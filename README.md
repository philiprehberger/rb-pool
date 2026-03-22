# philiprehberger-pool

[![Tests](https://github.com/philiprehberger/rb-pool/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-pool/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-pool.svg)](https://rubygems.org/gems/philiprehberger-pool)
[![License](https://img.shields.io/github/license/philiprehberger/rb-pool)](LICENSE)

Generic thread-safe object pool with idle timeout and health checks

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem 'philiprehberger-pool'
```

Or install directly:

```bash
gem install philiprehberger-pool
```

## Usage

```ruby
require 'philiprehberger/pool'

pool = Philiprehberger::Pool.new(size: 10, timeout: 5) { create_connection }

pool.with do |conn|
  conn.query('SELECT 1')
end
```

### Health Checks

```ruby
pool = Philiprehberger::Pool.new(size: 5, timeout: 3, health_check: ->(conn) { conn.ping }) do
  Database.connect
end
```

### Pool Statistics

```ruby
pool.stats
# => { size: 10, created: 3, available: 2, in_use: 1 }
```

### Manual Checkout

```ruby
resource = pool.checkout
# ... use resource ...
pool.checkin(resource)
```

### Shutdown

```ruby
pool.shutdown  # closes all resources, rejects new checkouts
```

## API

### `Philiprehberger::Pool`

| Method | Description |
|--------|-------------|
| `.new(size:, timeout:, health_check:) { block }` | Create a new pool with a factory block |
| `#checkout { \|resource\| ... }` | Checkout a resource, auto-return after block |
| `#with { \|resource\| ... }` | Alias for `checkout` |
| `#checkin(resource)` | Manually return a resource to the pool |
| `#size` | Configured maximum pool size |
| `#available` | Number of idle resources in the pool |
| `#in_use` | Number of currently checked-out resources |
| `#stats` | Hash with size, created, available, and in_use counts |
| `#shutdown` | Drain the pool and close all resources |
| `#shutdown?` | Whether the pool has been shut down |

## Development

```bash
bundle install
bundle exec rspec      # Run tests
bundle exec rubocop    # Check code style
```

## License

MIT
