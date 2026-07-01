# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-06-30

### Added

- `charles` action: launches Charles Proxy on macOS, generating its `.config`
  XML at runtime from a simplified `charles.yml` (see
  [`example/charles.yml`](example/charles.yml)) instead of requiring
  developers to hand-edit and commit Charles's own exported XML.
- `proxy.enable_socks` and `proxy.ssl` for controlling Charles's SOCKS proxy
  and SSL decryption, including per-host port overrides and an
  `include`/`exclude` form for carving hosts out of SSL decryption.
- `recording.hosts`, using a generalized location matcher
  (`protocol`/`host`/`port`/`path`/`query`, each optional) shared with future
  location-based config.
- `access_control.ip_ranges` in `charles.yml` (with an `"all"` shorthand for
  `0.0.0.0/0`), merged at runtime with the per-developer `ip_ranges` action
  option — CIDR notation or bare IPs (treated as `/32`).
- `registered_name` / `registered_key` action options for Charles Proxy
  license registration, sourced from env vars rather than committed config.
- Automatic EULA acceptance in the generated config.
- Clear, actionable errors (instead of raw Ruby exceptions) for common
  `charles.yml` mistakes: a missing file, invalid YAML syntax, YAML that
  isn't a mapping at the top level, and malformed `ip_ranges` CIDR entries.

### Known limitations

- Charles's `toolConfiguration` tools (Breakpoints, Rewrite, Map Remote,
  Block/Allow List, etc.) are not yet supported — see
  [`docs/tool-configuration.md`](docs/tool-configuration.md) for the
  per-tool evaluation and rationale.

[Unreleased]: https://github.com/jakekrog/fastlane-plugin-charles/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/jakekrog/fastlane-plugin-charles/releases/tag/v0.1.0
