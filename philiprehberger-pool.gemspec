# frozen_string_literal: true

require_relative 'lib/philiprehberger/pool/version'

Gem::Specification.new do |spec|
  spec.name = 'philiprehberger-pool'
  spec.version = Philiprehberger::Pool::VERSION
  spec.authors = ['philiprehberger']
  spec.email = ['philiprehberger@users.noreply.github.com']

  spec.summary = 'Generic thread-safe object pool with idle timeout and health checks'
  spec.description = 'A generic thread-safe object pool for Ruby with configurable size, checkout timeouts, ' \
                     'idle timeout eviction, health checks, and lazy resource creation.'
  spec.homepage = 'https://github.com/philiprehberger/rb-pool'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
