# Running the Example Application

## The example app is already in the repo

`src/main/` *is* a minimal example channel:

- `source/main.brs` — channel entry point, shows the scene
- `components/AppScene.{xml,brs}` — creates the `UnleashTask`, evaluates a
  feature, and renders its state on screen
- `components/UnleashTask.{xml,brs}` — the SDK's background thread

You can run it two ways: on your **desktop** with the
[`brs-desktop`](https://github.com/lvcabral/brs-desktop) simulator (easiest, no
hardware), or on a **physical Roku** in developer mode. Either way you first
configure the demo and build the channel zip.

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

## Step 2 — Build the channel package

```sh
make package        # -> build/package.zip
```

---

## Option A — Run on desktop with brs-desktop (recommended)

[`brs-desktop`](https://github.com/lvcabral/brs-desktop) ("BrightScript
Simulator") is a cross-platform (Windows/macOS/Linux) Roku simulator built on
[`brs-engine`](https://github.com/lvcabral/brs-engine). It runs a channel `.zip`
directly on your machine.

> **Note:** SceneGraph support in brs-desktop 2.x is **alpha** — components may
> not render exactly as on a device, and some features are unimplemented. Our
> demo uses a `Scene`, a `Task`, and `Label`s; expect it to run, but treat the
> simulator as a convenience, not a substitute for a final on-device check. See
> the [limitations doc](https://github.com/lvcabral/brs-engine/blob/scenegraph/docs/limitations.md).

### Install

Download an installer for your OS from the
[Releases page](https://github.com/lvcabral/brs-desktop/releases) (or build from
source per its README).

### Run the demo

The simplest path is to drag `build/package.zip` onto the simulator window.

To launch from the command line (and have it open the package on startup),
point the `BRS_DESKTOP` variable at the binary and use the `sim` target:

```sh
# macOS
make sim BRS_DESKTOP="/Applications/BrightScript Simulator.app/Contents/MacOS/BrightScript Simulator"

# Linux (AppImage)
make sim BRS_DESKTOP="$HOME/Applications/BrightScript Simulator.AppImage"

# Windows (Git Bash / WSL)
make sim BRS_DESKTOP="/c/Program Files/BrightScript Simulator/BrightScript Simulator.exe"
```

`make sim` runs the package with `-r` (telnet console on 8085) and `-c` (opens
the BrightScript console). Useful flags if you invoke the binary directly:

| Flag | Purpose |
|------|---------|
| `-o <path>` / `<path>` | Open a `.zip` or `.brs` on startup |
| `-c` / `--console` | Open the BrightScript console |
| `-r` / `--rc` | Enable telnet remote console on port 8085 |
| `-w [<port>]` / `--web` | Enable the Web Installer (port 80) |
| `-p <pwd>` / `--pwd` | Set the Web Installer password |
| `-f` / `--fullscreen`, `-m <sd\|hd\|fhd>` | Window / display mode |

### Sideload / logs against the simulator

Because brs-desktop exposes the same Web Installer (port 80) and telnet console
(port 8085) as a real device, the `install` and `logs` targets work against it
at `localhost`. Launch the simulator with the web installer enabled
(`-w -p <pwd>`), then:

```sh
make install ROKU_IP=localhost ROKU_PASS=<pwd>
make logs    ROKU_IP=localhost
```

You should see the SDK's debug lines (`unleash: refreshed N toggles`) and the
demo's evaluation prints in the console.

---

## Option B — Run on a physical Roku

### Enable developer mode

On the Roku remote press: **Home ×3, Up ×2, Right, Left, Right, Left, Right**.
The Development Settings screen shows the device **IP** and lets you set a
**dev web server password**. (Roku must be on the same LAN as your machine.)

### Sideload and watch logs

```sh
make install ROKU_IP=192.168.1.50 ROKU_PASS=yourpass
make logs    ROKU_IP=192.168.1.50
```

`make install` POSTs `build/package.zip` to the device's installer; you should
see `Install Success` and the demo scene appears on the TV. `make logs` telnets
to port `8085` for `print` output.

You can also sideload manually by opening `http://<roku-ip>/` in a browser and
uploading `build/package.zip` via the "Development Application Installer."

---

## Caveats

1. **Icons/splash**: the demo `manifest` references `pkg:/images/...` that don't
   exist. Sideloading still works (you may get a warning / blank icon). To
   silence it, drop any PNG/JPG at those paths under `src/main/images/` and add
   `images/**` to the `package` copy step.
2. **Integrating into your own channel** instead of the demo: copy
   `src/main/source/Unleash.brs` + the two `UnleashTask.*` files into your
   project and follow the "Usage" section in the README — you don't need
   `AppScene`/`main.brs` at all.
