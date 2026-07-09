# Charles `fastlane` Plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-charles)
[![Gem Version](https://img.shields.io/gem/v/fastlane-plugin-charles.svg)](https://rubygems.org/gems/fastlane-plugin-charles)
[![Test](https://github.com/jakekrog/fastlane-plugin-charles/actions/workflows/test.yml/badge.svg)](https://github.com/jakekrog/fastlane-plugin-charles/actions/workflows/test.yml)
[![pre-commit](https://github.com/jakekrog/fastlane-plugin-charles/actions/workflows/pre-commit.yml/badge.svg)](https://github.com/jakekrog/fastlane-plugin-charles/actions/workflows/pre-commit.yml)
[![License: MIT](https://img.shields.io/github/license/jakekrog/fastlane-plugin-charles.svg)](LICENSE)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-charles`, add it to your project by running:

```bash
fastlane add_plugin charles
```

## About charles

Run [Charles Proxy](https://www.charlesproxy.com/) from a fastlane lane, generating its `.config` file at runtime from a simplified YAML config (see [`example/charles.yml`](example/charles.yml)) that a team can commit and share, instead of hand-editing (and committing) Charles's own exported XML.

Currently macOS only (the default `app_path` points at the standard macOS Charles install).

### Options

| Key | Env var | Description | Default |
| ----- | --------- | -------------- | --------- |
| `app_path` | `FL_CHARLES_APP_PATH` | Path to the Charles application executable | `/Applications/Charles.app/Contents/MacOS/Charles` |
| `config_path` | `FL_CHARLES_CONFIG_PATH` | Path to a simplified Charles YAML config (see [`example/charles.yml`](example/charles.yml)) | `charles.yml` |
| `registered_name` | `FL_CHARLES_REGISTERED_NAME` | Registered name for your Charles Proxy license | none |
| `registered_key` | `FL_CHARLES_REGISTERED_KEY` | License key for your Charles Proxy registration | none |
| `ip_ranges` | `FL_CHARLES_IP_RANGES` | Per-developer IP ranges permitted to access the proxy | `[]` |
| `debug` | `FL_CHARLES_DEBUG` | Enable debug-level logging for this Charles session | `false` |
| `data_path` | `FL_CHARLES_DATA_PATH` | Charles application data directory to use (passes `--data`) | none |
| `headless` | `FL_CHARLES_HEADLESS` | Launch Charles without a UI (passes `--headless`) | `false` |
| `throttling` | `FL_CHARLES_THROTTLING` | Activate throttling for this Charles session (passes `--throttling`) | `false` |

`registered_name` and `registered_key` are intentionally kept out of `charles.yml` since they're per-developer secrets, not shared team config — set them via env vars (or a `.env` file fastlane will load) instead of committing them. They must be provided together.

`ip_ranges` works as a hybrid: the `ip_ranges` action option/env var is for ranges that only apply to one developer (e.g. their own machine), while ranges that genuinely apply to the whole team (a shared corporate subnet, or `"all"` as shorthand for `0.0.0.0/0`) belong in `charles.yml`'s `access_control.ip_ranges` instead — the two lists are merged at runtime. Each entry can be full CIDR notation (`10.0.1.20/32`) or a bare IP (`10.0.1.20`), which is treated as `/32` (that single host).

See [`example/.env.example`](example/.env.example) for a template covering these env vars — copy it to `.env` (which stays gitignored) rather than committing real values.

```ruby
charles # Use default paths
charles(app_path: "/path/to/Charles.app/Contents/MacOS/Charles")
charles(config_path: "/path/to/charles.yml")
charles(app_path: "/custom/path/to/Charles", config_path: "/custom/path/to/charles.yml")
charles(debug: true)
charles(data_path: "/tmp/charles-data")
charles(headless: true)
charles(throttling: true)
```

## Example

Check out the [example `Fastfile`](fastlane/Fastfile) to see how to use this plugin. Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

[`example/charles.yml`](example/charles.yml) shows the simplified schema this plugin generates a Charles `.config` file from at runtime.

`charles.yml` doesn't yet cover Charles's `toolConfiguration` tools (Breakpoints, Rewrite, Map Remote, Block List, etc.) — see [`docs/tool-configuration.md`](docs/tool-configuration.md) for the per-tool evaluation and why that's deferred to a future release.

The Charles binary also exposes a broader CLI (`--headless`, `convert`, `filter`, `ssl`, …) beyond the `--config` launch path this plugin uses today — see [`docs/charles-cli.md`](docs/charles-cli.md) for a snapshot of that surface and an incremental support roadmap.

## Run tests for this plugin

To run both the tests, and code style validation, run

```bash
bundle exec rake
```

To automatically fix many of the styling issues, use

```bash
bundle exec rubocop -a
```

## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to this repository. See [CONTRIBUTING.md](CONTRIBUTING.md) if you'd like to open a PR, [CHANGELOG.md](CHANGELOG.md) for release history, [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for community guidelines, and [SECURITY.md](SECURITY.md) to report a vulnerability.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
