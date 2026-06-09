# Unleash BrightScript SDK — Implementation Summary

The official Unleash BrightScript frontend SDK is built, tested, and staged in
git (no commit yet).

## What was built

Ported the LaunchDarkly Roku SDK's proven architecture (Task-thread networking
+ observed node fields + message port) and rewrote the protocol layer for the
Unleash Frontend API. Modules in `rawsrc/` are concatenated by the Makefile
into a single `Unleash.brs`:

| Module | Role |
|---|---|
| `UnleashConfig` | URL, token, app/env, intervals, headers, offline, log level |
| `UnleashContext` | context normalization + deterministic query-string builder |
| `UnleashEvaluation` | toggle parsing, `isEnabled`, `getVariant` (+ disabled fallback) |
| `UnleashMetrics` | yes/no + variant bucketing → `/client/metrics` payload |
| `UnleashStore` | registry-backed bootstrap of last-known toggles |
| `UnleashHTTP` | async `roUrlTransfer` GET/POST with timeout |
| `UnleashClient` | render-thread handle (`UnleashInit`, `UnleashClientSG`) |
| `UnleashTask.{brs,xml}` | background polling + metrics/register thread |

**Full parity** as requested: polling, `isEnabled`/`getVariant`/variants,
ready/error status, metrics + register, registry persistence/bootstrap, offline
mode. **GET transport** with context as query params (clean seam to add POST
later).

## Testing (no Roku hardware needed)

- **`npm test`** bundles the built library with the `test/` suite and runs it
  through the `@rokucommunity/brs` interpreter — **27 passing** unit tests
  covering encoding, context queries, response parsing, evaluation, metrics,
  and config.
- **`make lint`** type-checks the library + SceneGraph components with
  brighterscript — **zero diagnostics**.
- **`make package`** produces a sideloadable `build/package.zip` with a demo
  channel (`AppScene`) for on-device verification of the networking/threading
  paths that can't run off-device.

## Notes & decisions

- Switched the test interpreter from `brs@0.45` (crashes on load in this env)
  to the maintained `@rokucommunity/brs@0.47`.
- Apache-2.0 `LICENSE` + a `NOTICE` attributing the LaunchDarkly-derived
  architecture, per their license terms.
- Networking/SceneGraph logic is deliberately thin; all decision logic lives in
  pure functions so it's testable off-device.

## Open items for review

- The demo `manifest` references icon/splash images that were not created (a
  real channel needs them).
- The `NOTICE` copyright line guesses the Unleash legal entity
  ("Bricks Software AB") — correct if wrong.
