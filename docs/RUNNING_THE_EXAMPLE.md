# Running the Example Application

## The example app is already in the repo

`src/main/` *is* a minimal example channel:

- `source/main.brs` — channel entry point, shows the scene
- `components/AppScene.{xml,brs}` — creates the `UnleashTask`, evaluates a
  feature, and renders its state on screen
- `components/UnleashTask.{xml,brs}` — the SDK's background thread

## Why you need a device (or emulator)

The `npm test` path runs pure logic in the `brs` interpreter — but that
interpreter **does not render SceneGraph**. A real channel with
`roSGScreen`/scenes only runs on:

- a **physical Roku** in developer mode (the normal path), or
- Roku's official emulator (Windows-only beta).

So "running the example" = sideloading to a Roku.

## Step 1 — Point the demo at your Unleash

Edit `src/main/components/AppScene.brs` (in `init()`):

```brightscript
config = UnleashConfig("<your-frontend-token>", m.unleashNode)
config.setUrl("https://<your-unleash-host>/api/frontend")
config.setAppName("roku-demo")
...
m.demoFeature = "demo-feature"   ' <- a real toggle name in your project
```

Use a **frontend API token** (`...frontend...`), not a server token, and make
sure that toggle exists in the same environment.

## Step 2 — Enable developer mode on the Roku

On the Roku remote press: **Home ×3, Up ×2, Right, Left, Right, Left, Right**.
The Development Settings screen shows the device **IP** and lets you set a
**dev web server password**. (Roku must be on the same LAN as your machine.)

## Step 3 — Build and sideload

```sh
make install ROKU_IP=192.168.1.50 ROKU_PASS=yourpass
```

That runs `make package` (builds `build/package.zip`) and POSTs it to the
device's installer. You should see `Install Success`. The demo scene then
appears on the TV showing `demo-feature is ENABLED/disabled` and a status line.

> You can also sideload manually by opening `http://<roku-ip>/` in a browser
> and uploading `build/package.zip` via the "Development Application Installer."

## Step 4 — Watch logs

```sh
make logs ROKU_IP=192.168.1.50
```

This telnets to port `8085` where BrightScript `print` output goes — you'll see
the SDK's debug lines (`unleash: refreshed N toggles`) and the demo's
evaluation prints.

## Two caveats for a clean first run

1. **Icons/splash**: the demo `manifest` references `pkg:/images/...` that don't
   exist. Sideloading still works (you may get a warning / blank icon). To
   silence it, drop any PNG/JPG at those paths under `src/main/images/` and add
   `images/**` to the `package` copy step.
2. **Integrating into your own channel** instead of the demo: copy
   `src/main/source/Unleash.brs` + the two `UnleashTask.*` files into your
   project and follow the "Usage" section in the README — you don't need
   `AppScene`/`main.brs` at all.
