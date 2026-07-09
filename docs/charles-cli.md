# Charles Proxy CLI surface

Charles ships a command-line interface on the same binary this plugin launches
(`/Applications/Charles.app/Contents/MacOS/Charles` on macOS). Today the
plugin only uses `--config` (passed as `-config`) when starting a proxy
session. This doc snapshots the rest of the CLI as of Charles 5.2 so support
can be added incrementally without rediscovering the surface each time.

## Snapshot

Captured with:

```bash
/Applications/Charles.app/Contents/MacOS/Charles -h
/Applications/Charles.app/Contents/MacOS/Charles --version
```

| Field | Value |
| ----- | ----- |
| Charles version | 5.2 |
| Captured | 2026-07-09 |
| Binary | `/Applications/Charles.app/Contents/MacOS/Charles` |

Re-capture after upgrading Charles; the help text below is the source of
truth for what this doc evaluates, not a guarantee of future CLI stability.

## Verbatim help (`charles -h`)

```text
Charles Proxy command line interface

Usage: charles [file]...

Options
-------
 --config <path>   The config file to use
 --data <path>     The data directory to use
 --debug           Enable debug-level logging for this session
 --headless        Launch Charles in headless mode
 --throttling      Activate throttling
 --version         Output the current version

Commands
--------

Convert
=======
Convert a saved Charles session from one supported format to another.
The input and output formats are inferred from the file extensions.
Filter options may be supplied to drop matching transactions before writing.

Usage: convert <infile> <outfile> [filter options]

Supported input formats:
  .chlz    Charles session file
  .chls    Charles session file (Charles 4 and earlier)
  .chlsx   Charles session XML
  .har     HTTP Archive
  .saz     Fiddler session archive
  .trace   HTTP trace
  .pcap    Libpcap capture
  .xml     Charles XML session
  .json    Charles JSON session

Supported output formats:
  .chlz    Charles session file
  .chls    Charles session file (Charles 4 and earlier)
  .chlsx   Charles session XML
  .har     HTTP Archive
  .trace   HTTP trace
  .xml     Charles XML session
  .json    Charles JSON session
  .csv     Comma-separated values summary

Filter options (optional):
  --include-mime <pattern>     keep only transactions matching the MIME glob (repeatable)
  --exclude-mime <pattern>     drop transactions matching the MIME glob (repeatable)
  --include-host <pattern>     keep only transactions matching the host glob (repeatable)
  --exclude-host <pattern>     drop transactions matching the host glob (repeatable)
  --include-method <method>    keep only transactions with this HTTP method (repeatable)
  --exclude-method <method>    drop transactions with this HTTP method (repeatable)
  --max-response-size <bytes>  drop transactions whose response exceeds this size (suffixes: k, m, g)

Examples:
  charles convert capture.chls capture.har
  charles convert capture.chls capture.har --exclude-mime "video/*"

Filter
======
Filter a saved Charles session by removing transactions that match the given criteria.
The same filter options can also be passed to `convert` to filter and change format in one step.

Usage: filter <infile> <outfile> [options]

Options
  --include-mime <pattern>     keep only transactions matching the MIME glob (repeatable)
  --exclude-mime <pattern>     drop transactions matching the MIME glob (repeatable)
  --include-host <pattern>     keep only transactions matching the host glob (repeatable)
  --exclude-host <pattern>     drop transactions matching the host glob (repeatable)
  --include-method <method>    keep only transactions with this HTTP method (repeatable)
  --exclude-method <method>    drop transactions with this HTTP method (repeatable)
  --max-response-size <bytes>  drop transactions whose response exceeds this size (suffixes: k, m, g)

Examples:
  charles filter raw.chls filtered.chls --exclude-mime "video/*" --exclude-mime "audio/*"
  charles filter raw.chls filtered.chls --include-host "api.example.com" --max-response-size 1m

SSL
===
Export Charles SSL root certificate.
Usage: ssl export <file.pem>
       ssl export <file.crt>
       ssl export - pem
       ssl export - crt
       ssl export - p12 <password>

Install Charles SSL root certificate in iOS simulators
Usage: ssl iossim

Manage client SSL certificates
Usage: ssl client-certs

Manage secure store
Usage: ssl store
```

## Current plugin usage

`CharlesAction` already invokes:

```text
<app_path> -config <generated charles.config>
```

That maps to the `--config` option below. Nothing else from this surface is
wired through yet (neither the fastlane action nor `charles-proxy-cli`).

## Launch options

These apply to the default `charles [file]...` invocation (start Charles,
optionally opening session files).

| Option | Status | Notes |
| ------ | ------ | ----- |
| `--config <path>` | **Supported** | Plugin generates a temp `.config` from YAML and passes `-config`. Confirm whether `-config` and `--config` are interchangeable across platforms/versions when expanding coverage. |
| `--data <path>` | Deferred | Overrides Charles's application data directory. Useful for isolating CI/agent runs from a developer's interactive Charles profile, and may pair with `--headless`. Needs investigation of what lives under the data dir (profiles, SSL store, etc.). |
| `--debug` | **Supported** | Session-scoped debug logging. Exposed as the `debug` action option / `FL_CHARLES_DEBUG` env var. |
| `--headless` | High value | Launch without UI — the clearest fit for unattended lanes/CI. Should be an early follow-up once launch-option plumbing exists. |
| `--throttling` | Deferred | Activates throttling for the session. Only useful once throttling settings themselves are representable (likely via `toolConfiguration` / config XML, see [`tool-configuration.md`](tool-configuration.md)); a bare flag without shared throttle presets is low value. |
| `--version` | Low priority | Version probe. Handy for diagnostics/support, not for the main `charles` lane. Could be a separate helper/action later. |
| `[file]...` | Deferred | Positional session files to open on launch. Overlaps conceptually with post-run `convert`/`filter` workflows more than with "start a proxy from YAML." |

### Suggested incremental order (launch options)

1. Plumb optional launch flags through the action (`headless`, then `debug`).
2. Add `--data` once there's a concrete isolation story (CI temp dir, etc.).
3. Revisit `--throttling` only after throttle config can be expressed in YAML.
4. Treat `--version` / opening session files as separate, lower-priority surfaces.

## Commands

These are subcommands (`charles convert …`, `charles filter …`, `charles ssl …`),
not launch flags. They are a different product shape from "start Charles from
`charles.yml`" — likely separate fastlane actions and/or `charles-proxy-cli`
commands rather than options on the existing `charles` action.

### `convert`

Session format conversion with optional filter pass. Strong automation fit
for post-capture pipelines (e.g. `.chlz` → `.har` for sharing or tooling that
doesn't speak Charles's native format).

**Support sketch:** a dedicated action/CLI command that shells out to
`<app_path> convert <infile> <outfile> [filters…]`, inferring formats from
extensions the same way Charles does. Filter flags should be shared with
`filter` (see below).

### `filter`

Same filter criteria as `convert`, but keeps the session format. Implement
the filter option set once and reuse it for both commands:

| Flag | Repeatable | Notes |
| ---- | ---------- | ----- |
| `--include-mime <pattern>` | yes | MIME glob |
| `--exclude-mime <pattern>` | yes | MIME glob |
| `--include-host <pattern>` | yes | Host glob |
| `--exclude-host <pattern>` | yes | Host glob |
| `--include-method <method>` | yes | HTTP method |
| `--exclude-method <method>` | yes | HTTP method |
| `--max-response-size <bytes>` | no | Accepts `k`/`m`/`g` suffixes |

### `ssl`

Certificate / trust-store management. Several subcommands; depth of help
varies (top-level help only sketches them).

| Subcommand | Fit | Notes |
| ---------- | --- | ----- |
| `ssl export` | High value | Export root CA as `.pem` / `.crt`, or stdout (`- pem` / `- crt`), or `.p12` with password. Natural companion to proxy automation (install trust on devices/simulators). |
| `ssl iossim` | High value (iOS) | Install root cert into iOS simulators — pairs directly with mobile test lanes. |
| `ssl client-certs` | Needs discovery | Help text is a one-liner; capture fuller usage before designing an API. |
| `ssl store` | Needs discovery | Same — secure-store management; probe with `ssl store -h` (or equivalent) before implementing. |

### Suggested incremental order (commands)

1. `ssl export` + `ssl iossim` — highest leverage for mobile proxy workflows.
2. Shared filter-option plumbing, then `convert` (and `filter` if needed as its own entry point).
3. `ssl client-certs` / `ssl store` after capturing their full CLIs.

## Open questions

- Does the plugin keep a single `charles` action that grows launch flags, or
  split into `charles` (launch) + `charles_convert` / `charles_ssl_export`
  (etc.)? Separate actions match Charles's own command split and keep the
  launch action focused.
- Should `charles-proxy-cli` mirror any new actions 1:1, or only the ones that
  are useful outside fastlane?
- For `--data`: is a plugin-managed temp data dir the right default in CI, or
  an explicit opt-in?
- Confirm flag spelling (`-config` vs `--config`) and whether Windows
  `Charles.exe` exposes the same CLI surface before advertising
  cross-platform command support.
