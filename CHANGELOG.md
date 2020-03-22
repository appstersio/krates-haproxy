# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2020-03-20
### Added
- Docker: Make `/var/lib/acme` a volume by default.
- HAProxy: Use default binary and config file locations as recommended.
- HAProxy: Switch to run in `master-worker` mode and add support for graceful server configuration reload via 'SIGUSR2' signal.
- Makefile: Setup end-2-end developer workflow and enable 'frp' tunnel to validate integration with LetsEncrypt.
- Makefile: Cache locally '/var/lib/acme' and '/etc/ssl/private' folders in './tmp' for introspection and troubleshooting.
- ACME: Switch to use LEGO project to obtain and renew LetsEncrypt certificates for the instance + support for LetsEncrypt staging endpoint in 'debug' mode.

### Changed
- Celluloid: Switch to use newer `supervise` syntax for our supervisors in `bin/haproxy` (celluloud 0.17.4).
- AcmeWorker: Fix issue with `FileUtils.copy` and use `cp` utility instead (via system call).
- HAProxy: Switch to use the most recent released version of the software (`v2.1.3` ).
- HAProxy: Enable 'debug' mode in the logs to improve diagnostics and troubleshooting.
- HAProxy: Get rid of the configuration warnings in the server logs.
- Exclude 'tmp' folder from being tracked by Git.
- HAProxy: Include an actual copy of 'haproxy.cfg' for reference purposes.

### Removed
- ACME: All interactions with 'acmetool' since it has been lagging behind with ACME v2 support.
