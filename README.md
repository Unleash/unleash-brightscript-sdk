# Unleash SDK for Roku / BrightScript

A frontend (client-side) [Unleash](https://www.getunleash.io/) SDK for Roku
channels, written in BrightScript. It evaluates feature toggles against the
[Unleash Frontend API](https://docs.getunleash.io/reference/front-end-api)
(`/api/frontend`) or [Unleash Edge](https://docs.getunleash.io/reference/unleash-edge).

The networking runs on a SceneGraph `Task` thread, so the render thread is
never blocked. Toggles are polled on an interval, cached to the registry for
fast startup, and evaluation metrics are reported back to Unleash.

> Architecture and threading model are adapted from the Apache-2.0 licensed
> [LaunchDarkly Roku SDK](https://github.com/launchdarkly/roku-client-sdk).
> See [`NOTICE`](./NOTICE).

## Features

- `isEnabled(name)` and `getVariant(name)` evaluation
- Background polling (`refreshInterval`) on a Task thread
- Registry-backed bootstrap (last-known toggles available before first fetch)
- Metrics: per-toggle yes/no + variant counts posted to `/client/metrics`,
  plus a `/client/register` call on startup
- Custom auth header name and extra headers
- Offline mode

## Installation

The SDK is a single generated BrightScript file plus one SceneGraph component.

```sh
make build      # concatenates rawsrc/*.brs -> src/main/source/Unleash.brs
```

Copy into your channel:

- `src/main/source/Unleash.brs`            → `pkg:/source/Unleash.brs`
- `src/main/components/UnleashTask.brs`     → `pkg:/components/UnleashTask.brs`
- `src/main/components/UnleashTask.xml`     → `pkg:/components/UnleashTask.xml`

The `UnleashTask.xml` includes `pkg:/source/Unleash.brs`; adjust the path if
your project lays out components differently.

## Usage

In your scene XML, add the task node:

```xml
<children>
    <UnleashTask id="unleash"/>
</children>
<script type="text/brightscript" uri="pkg:/source/Unleash.brs"/>
```

In the scene's BrightScript:

```brightscript
function init() as Void
    node = m.top.findNode("unleash")

    config = UnleashConfig("<your-frontend-token>", node)
    config.setUrl("https://<your-unleash-host>/api/frontend")
    config.setAppName("my-roku-channel")
    config.setRefreshIntervalSeconds(15)

    context = UnleashCreateContext({
        userId: "user-123",
        properties: { region: "eu" }
    })

    UnleashInit(config, context)          ' starts the background Task
    m.unleash = UnleashClientSG(node)     ' render-thread handle

    node.observeField("toggles", "onToggles")
    node.observeField("status", "onStatus")
end function

function onToggles() as Void
    if m.unleash.isEnabled("new-home-screen") then
        ' ...
    end if

    variant = m.unleash.getVariant("home-layout")
    print variant.name, variant.enabled, variant.payload
end function
```

To change the context later (e.g. after sign-in), call
`m.unleash.updateContext(UnleashCreateContext({...}))` — this triggers an
immediate refresh.

## API

### `UnleashConfig(clientKey, taskNode)`

| Method | Description | Default |
| --- | --- | --- |
| `setUrl(url)` | Frontend API base URL (returns `false` if not http/https) | `http://localhost:4242/api/frontend` |
| `setAppName(name)` | Application name (also sent as context + header) | `unleash-brightscript` |
| `setEnvironment(env)` | Context environment | `default` |
| `setRefreshIntervalSeconds(n)` | Poll interval; `0` disables polling | `30` |
| `setMetricsIntervalSeconds(n)` | Metrics flush interval | `30` |
| `setDisableMetrics(bool)` | Disable metrics + register calls | `false` |
| `setOffline(bool)` | Skip all network calls | `false` |
| `setLogLevel(level)` | `UnleashLogLevels().{none,error,warn,info,debug}` | `warn` |
| `setHeaderName(name)` | Authorization header name | `Authorization` |
| `addHeader(name, value)` | Extra header on every request | – |

### `UnleashCreateContext(props)`

Recognised keys: `userId`, `sessionId`, `remoteAddress`, `currentTime`, and a
`properties` map for custom fields. Unknown top-level keys are dropped.

### `UnleashClientSG(taskNode)`

| Method | Returns | Description |
| --- | --- | --- |
| `isEnabled(name)` | `Boolean` | Whether the toggle is enabled |
| `getVariant(name)` | `Object` | `{ name, enabled, feature_enabled, payload? }`; the disabled variant for unknown toggles |
| `getAllToggles()` | `Object` | Map of toggle name → toggle |
| `getStatus()` / `isReady()` | `Integer` / `Boolean` | `UnleashStatus().{notReady,ready,error}` |
| `updateContext(context)` | – | Replace context and refresh |
| `flushMetrics()` | – | Force metrics to be sent now |

## Testing

Pure logic (encoding, context query building, response parsing, evaluation,
metrics bucketing, config) is unit tested **off-device** with the
[`brs`](https://github.com/rokucommunity/brs) interpreter — no Roku hardware
required.

```sh
npm install
npm test          # make build + run the brs-based suite
make lint         # brighterscript type-check of the library + components
```

`npm test` bundles `src/main/source/Unleash.brs` with the files in `test/` and
runs them through `brs`, then fails the process if any assertion fails.

Networking and SceneGraph threading are verified on-device using the demo
channel under `src/main/` (`make package` builds a sideloadable `build/package.zip`).

## Project layout

```
rawsrc/                     source modules (concatenated into one file)
src/main/source/Unleash.brs generated library (git-ignored)
src/main/components/        UnleashTask (SDK) + AppScene (demo)
src/main/source/main.brs    demo channel entry point
test/                       off-device brs unit tests
scripts/run-tests.js        test runner
Makefile                    build / test / lint / package
```

## License

Apache License 2.0 — see [`LICENSE`](./LICENSE) and [`NOTICE`](./NOTICE).
