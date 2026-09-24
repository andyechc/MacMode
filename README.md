# MacMode

> **Status: scaffold + domain complete, all tests green. No system
> integration yet — the app launches as a menu bar agent and shows its
> (persisted) mode, but does not change Function Keys.**

MacMode is a lightweight native macOS menu bar utility that switches the Mac
between two system profiles — **DEV** and **GAMING** — with a single fast
control. The first capability (MVP) is controlling the behavior of the Mac's
function keys.

The problem it solves: switching usage profiles on macOS today means digging
through System Settings every time. MacMode puts that switch one click away,
in the menu bar.

See [`SPEC.md`](SPEC.md) for the full product and engineering specification,
and [`AGENTS.md`](AGENTS.md) for agent working rules.

## Features

### Available

* Menu bar agent (window-style popover) with mode select, per-mode accent
  color, Information and Settings windows, mode library editing
  (add/rename/recolor/delete), persisted mode, and clean quit. Verified:
  `xcodebuild build`, `xcodebuild test` (23 tests), launch as background
  process.
* Domain layer: `MacMode`, `ModeManager` (idempotent transitions, explicit
  errors, `UserDefaults` persistence), `FeatureManager` (`SystemFeature`
  fan-out), `OSLog` logging. All unit-tested with mocks; no system touched.

### Planned

* DEV / GAMING mode switch from the menu bar (one interaction).
* Function Key behavior controlled by the active mode.
* Mode persistence across restarts (with system-state synchronization).
* Explicit error handling with user-understandable messages.
* Launch at Login (after MVP works).
* See `SPEC.md` §32 for the full roadmap (v0.2 → v1.0).

## How It Works

```text
Menu Bar (SwiftUI)
   ↓
Mode Manager  (source of truth: DEV | GAMING)
   ↓
Feature Manager  (applies SystemFeature list per mode)
   ↓
macOS System Integration  (isolated controllers, e.g. FunctionKeyController)
```

SwiftUI views never call low-level system APIs directly. All macOS
integration lives behind explicit protocols so business logic stays testable
with mocks.

## Current Modes

Planned behavior (not yet implemented):

* **DEV** — profile for development work. Function Keys set to the
  development configuration.
* **GAMING** — profile for gaming. Function Keys set to the gaming
  configuration.

The exact Function Key configurations per mode will be locked after the
mandatory API research (`docs/research/function-keys.md`).

## Requirements

Determined from the actual environment (not invented):

* macOS 27.0 host (build 26A428, Apple Silicon arm64).
* Xcode 27.0 (27A266a).
* Swift 6.4.
* macOS deployment target: **TBD — proposed 14.0**, to be confirmed by the
  Function Key API research (`SPEC.md` requires deriving it from the APIs
  actually used).
* Required permissions: **TBD** — under research. Only the strict minimum
  will be requested.

## Installation

Developer installation (verified 2026-09-24 on macOS 27.0 / Xcode 27.0):

```text
git clone https://github.com/andyechc/MacMode.git
→ Open MacMode.xcodeproj in Xcode (or: xcodegen generate, project.yml is source of truth)
→ Build (⌘B)
→ Run (⌘R, verified: launches as a background menu bar process)
```

No release artifact exists yet, so there is no download/install flow to
document. See "Future Distribution" in `SPEC.md`/`AGENTS.md` context:
a landing page (e.g. `macmode.app`) is future scope — no domain has been
registered and no website exists in this repository.

## Development

* Project structure: see [`docs/architecture.md`](docs/architecture.md)
  (planned layout under `app/`, plus `docs/`).
* Project generation: `xcodegen generate` (from `project.yml`, once added).
* Build: `xcodebuild -scheme MacMode -configuration Debug -destination 'platform=macOS' build`
* Tests: `xcodebuild test -scheme MacMode -destination 'platform=macOS'`
* Workflow: small commits (`feat:`/`fix:`/`test:`/`docs:`), build + test
  after each meaningful change. See [`docs/development.md`](docs/development.md).

## Architecture

Layered, per `SPEC.md` §9:

```text
SwiftUI (MenuBarView, ModeSelector, SettingsView)
   ↓
Application (ModeManager, FeatureManager)
   ↓
Domain (MacMode, SystemFeature, FeatureState)
   ↓
System Integration (FunctionKeyController, LaunchAtLogin, permissions)
```

Single source of truth for the active mode; desired state is reconciled
against actual system state and the UI reflects the actual state when known.
Full detail: [`docs/architecture.md`](docs/architecture.md).

## Permissions

To be determined by `docs/research/function-keys.md`. MacMode will request
only strictly necessary permissions, explain why before directing the user
to System Settings, and never attempt to bypass macOS security mechanisms.

## Privacy

MacMode does not collect keyboard input, telemetry, analytics, or any
unnecessary user data. It manipulates only local macOS configuration
required for its functionality, works fully offline, and has no account
system, no network communication, and no cloud sync.

## Roadmap

* v0.1 — MVP: menu bar DEV/GAMING switch, Function Key integration,
  persistence, error/permission handling, tests.
* v0.2 — Launch at Login, keyboard shortcut, notifications.
* v0.3+ — more features, configurable profiles, app detection.
* v1.0 — user profiles, automatic switching.

Marked clearly: everything above is **planned**, nothing is implemented.
Details in `SPEC.md` §32.

## Contributing

* Follow `SPEC.md` + `AGENTS.md`.
* Small, focused commits; no giant unrelated changes.
* Research before touching system APIs; document FACT vs ASSUMPTION vs
  UNVERIFIED.
* Never commit secrets, certificates, provisioning profiles, build
  artifacts, or Xcode user state (see `.gitignore`).
* Tests are mandatory for domain logic; system behavior must be manually
  verified on a real Mac and documented.

## License

MIT — see [`LICENSE`](LICENSE).
