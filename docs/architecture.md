# Architecture

Living document. Boundaries below follow `SPEC.md` §7–§9; the Function Key
integration details stay **TBD** until `docs/research/function-keys.md`
lands.

## Layers

```text
┌─────────────────────────────┐
│          SwiftUI            │
│ MenuBarView / ModeSelector  │
│ SettingsView / Components   │
└──────────────┬──────────────┘
               │ observes only
┌──────────────▼──────────────┐
│        Application          │
│ ModeManager (source of      │
│   truth) / FeatureManager   │
└──────────────┬──────────────┘
               │ applies features
┌──────────────▼──────────────┐
│           Domain            │
│ MacMode / SystemFeature /   │
│ FeatureState                │
└──────────────┬──────────────┘
               │ isolated protocols
┌──────────────▼──────────────┐
│     System Integration      │
│ FunctionKeyController /     │
│ LaunchAtLogin / permissions │
└─────────────────────────────┘
```

## Rules

1. SwiftUI observes state; it never calls IOKit/HID/defaults/System Settings
   APIs directly.
2. `ModeManager` owns `currentMode: MacMode` (never a bare boolean).
3. `FeatureManager` owns the `[SystemFeature]` list; adding a feature must
   not require touching existing features or views.
4. Each `SystemFeature` maps a mode to a concrete system change and reports
   success/failure explicitly (no `try?` on important transitions).
5. Desired state vs actual system state are tracked separately; the UI shows
   actual state when known (`SPEC.md` §10–§12).
6. Persistence is `UserDefaults` (or `@AppStorage`); no database. On launch:
   read → validate against system → synchronize if needed → display.
7. Logging via `OSLog` (`com.macmode` subsystem); never log keystrokes,
   typed text, or personal data.
8. All collaborators behind protocols + dependency injection so unit tests
   use mocks (`MockFunctionKeyController`) without touching the real Mac.

## UI decisions

* `MenuBarExtra` uses `.menuBarExtraStyle(.window)` (explicit). Verified
  2026-09-24: the default `.automatic` style renders content as menu items,
  where `Toggle(.switch)` and custom-drawn switch controls do not paint
  (invisible rows with menu-like blue hover). The window style renders a
  real popover where standard controls work. Source: Apple Developer
  Documentation, `MenuBarExtra` / `MenuBarExtraStyle`.

## Planned module layout (under `app/`)

Per `SPEC.md` §22, adapted once the Xcode project exists. Directories are
created when they gain real content, not before.

## Open decisions

* macOS deployment target (proposed 14.0; confirm via research).
* Exact `FunctionKeyController` shape (confirm via research).
* Permission set (confirm via research).
