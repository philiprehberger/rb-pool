# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this gem adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.5] - 2026-03-23

### Fixed
- Standardize README to match template (installation order, code fences, license section, one-liner format)
- Update gemspec summary to match README description

## [0.1.4] - 2026-03-22

### Changed
- Fix README badges to match template (Tests, Gem Version, License)

## [0.1.3] - 2026-03-22

### Changed

- Expand test coverage to 30+ examples covering sequential checkouts, resource reuse, factory call counts, exception safety, double checkin, shutdown behavior, and stats accuracy

## [0.1.2] - 2026-03-22

### Fixed

- Fix CHANGELOG header wording
- Add bug_tracker_uri to gemspec

## [0.1.1] - 2026-03-22

### Changed
- Improve source code, tests, and rubocop compliance

## [0.1.0] - 2026-03-22

### Added

- Initial release
- Thread-safe object pool with configurable size
- `with` block for automatic checkout/checkin
- Manual `checkout` and `checkin` methods
- Configurable checkout timeout with `TimeoutError`
- Idle timeout eviction for stale resources
- Health check callback to validate resources before use
- Lazy resource creation on demand
- Pool stats reporting (size, available, in_use)
- Graceful shutdown with `shutdown` and `shutdown?`

[Unreleased]: https://github.com/philiprehberger/rb-pool/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/philiprehberger/rb-pool/releases/tag/v0.1.0
