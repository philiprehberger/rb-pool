# frozen_string_literal: true

require_relative 'lib/philiprehberger/pool/version'

Gem::Specification.new do |spec|
  spec.name          = 'philiprehberger-pool'
  spec.version       = Philiprehberger::Pool::VERSION
  spec.authors       = ['Philip Rehberger']
  spec.email         = ['me@philiprehberger.com']

  spec.summary       = 'Generic thread-safe object pool with idle timeout and health checks'
  spec.description   = 'A reusable, thread-safe object pool for managing expensive resources like ' \
                        'database connections, HTTP clients, and sockets. Supports lazy creation, ' \
                        'checkout timeout, idle eviction, and health checks.'
  spec.homepage      = 'https://github.com/philiprehberger/rb-pool'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = spec.homepage
  spec.metadata['changelog_uri']         = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri']       = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
