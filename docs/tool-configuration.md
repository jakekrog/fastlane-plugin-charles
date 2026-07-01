# `toolConfiguration` in `charles.yml`

Charles's exported `.config` XML has a `toolConfiguration` section covering ~15
individual tool panes (Breakpoints, Rewrite, Map Remote, Block List, etc.).
None of these are currently represented in the simplified `charles.yml`
schema — this doc records why, and how each entry was evaluated, so that
context isn't lost if this gets picked up later (by us or anyone else).

## Decision

Deferred entirely for v0.1. The basic plugin (proxy SSL/SOCKS, recording,
access control, registration, EULA acceptance) is complete and tested without
touching `toolConfiguration`. Adding tool support is a meaningfully separate
piece of work with its own open design questions (see below), so it's being
left for a future release rather than block/bloat this one.

## Per-entry evaluation

### Bad fits regardless of schema design

These carry state that's tied to one developer's machine or a specific,
momentary debugging session — committing them to a shared YAML wouldn't be
portable across a team even if the schema were generalized:

- **Mirror** — `savePath` is a personal, ephemeral local folder.
- **Auto Save** — same problem, `savePath` is a personal local folder.
- **Map Local** — `dest` is an absolute local filesystem path; every
  developer's checkout lives somewhere different.
- **Breakpoints** — pausing a specific request mid-flight for manual
  inspection/editing is inherently a live, interactive debugging action. If
  baked into shared config, every developer running `charles` non-interactively
  would have matching requests freeze waiting on manual intervention in the
  Charles UI — directly at odds with launching Charles unattended from a lane.
  Notably, Charles's own Breakpoints pane already has dedicated import/export
  functionality, suggesting its authors also expect this to be handled
  out-of-band rather than as part of the global config.
- **Port Forwarding** / **Reverse Proxies** — both have a `sourceAddress` tied
  to a specific local network IP; not portable as exported, even if the
  general concept might be team-relevant.

### Good fits — same cheap `hosts`/location + toggle pattern already in use

No local/session-specific state, and the schema is basically what `recording`
already uses (a list of location matchers + an enabled flag):

- **No Caching**
- **Block Cookies**
- **Allow List**
- **Block List**
- **Client Process** — despite the name, this doesn't filter by which local
  process made a request; it's a toggle that annotates each request with its
  originating process, optionally scoped to selected destination locations.
  Confirmed via Charles's own in-app help text.

### Plausible value, needs the richer location schema

The generalized location matcher (`protocol`/`host`/`port`/`path`/`query`,
each optional — see `Helper::CharlesHelper.normalize_location_entry` /
`build_location_element`) already exists as of the `recording.hosts` work, so
these are less of a leap than they used to be, but still meaningfully more
complex:

- **Map Remote** — redirects one location to another (e.g. "point the app at
  staging instead of prod"). Closest thing to a universally useful "commonly
  shared debugging pathway."
- **Rewrite** — header/body injection per matched location + rule. By far the
  most complex schema encountered (rule types, match/replace semantics, case
  sensitivity, etc.) — highest implementation cost.
- **Viewer Mappings** — tells Charles how to render certain response types
  (e.g. treat an endpoint as protobuf). More of a presentation preference than
  proxy behavior; lower priority.
- **DNS Spoofing** — redirects a hostname to a specific IP. Could be shared if
  a team always points a host at the same staging IP, but the target IP is the
  kind of thing that can vary per-environment.

## Open questions for whenever this is picked up

- Should tools with their own native import/export (Breakpoints being the
  clearest example) get their own separate, importable config file instead of
  being folded into `charles.yml` — i.e. a hybrid model where a team shares
  multiple purpose-specific config files for common debugging pathways? This
  came up as an idea but was judged likely overkill for v0.1.
- Whether/how to validate the YAML schema once it grows past the current
  handful of keys (JSON Schema vs. hand-rolled `UI.user_error!` checks) — see
  the discussion in-session; the conclusion was to revisit once the full
  shape (including any tool-configuration entries) is known, since the
  dependency tradeoffs of JSON Schema (mainly Bundler version-constraint
  collisions in consuming projects, not size/speed) are easier to weigh
  against a stable target schema than a partial one.
