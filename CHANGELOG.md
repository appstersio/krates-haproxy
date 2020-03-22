# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Makefile: Setup end-2-end developer workflow and enable 'frp' tunnel to validate integration with LetsEncrypt.
- Makefile: Cache locally '/var/lib/acme' and '/etc/ssl/private' folders in './tmp' for introspection and troubleshooting.
- ACME: Switch to use LEGO project to obtain and renew LetsEncrypt certificates for the instance + support for LetsEncrypt staging endpoint in 'debug' mode.

### Changed
- HAProxy: Enable 'debug' mode in the logs to improve diagnostics and troubleshooting.
- HAProxy: Get rid of the configuration warnings in the server logs.
- Exclude 'tmp' folder from being tracked by Git.
- HAProxy: Include an actual copy of 'haproxy.cfg' for reference purposes.

### Removed
- ACME: All interactions with 'acmetool' since it has been lagging behind with ACME v2 support.