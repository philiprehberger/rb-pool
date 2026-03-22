# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-03-21

### Added
- Initial release
- Generic thread-safe object pool with configurable size
- Block-based `checkout`/`with` for automatic resource return
- Lazy resource creation up to configured pool size
- Configurable checkout timeout with `TimeoutError`
- Optional health check callback for resource validation
- Pool statistics via `stats` (size, created, available, in_use)
- Graceful `shutdown` with resource cleanup
