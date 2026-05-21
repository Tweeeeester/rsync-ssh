# Changelog

## [Unreleased]

### Added
- Initial project scaffold: Dockerfile, entrypoint, sync script, docker-compose, and config template
- Healthcheck: sync.sh writes /tmp/last-sync after each run; Docker healthcheck fails if no run in 2 hours
