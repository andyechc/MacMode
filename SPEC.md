# MacMode — Product & Engineering Specification

## 1. Project

**Name:** MacMode
**Platform:** macOS
**Type:** Native menu bar utility
**Language:** Swift
**UI:** SwiftUI
**System integration:** AppKit + appropriate macOS system APIs
**Minimum target:** Choose the minimum macOS version based on the APIs actually required; do not invent compatibility requirements.

MacMode is a lightweight macOS menu bar application that allows the user to switch between two system profiles:

* `DEV`
* `GAMING`

The first MVP capability is controlling the behavior of the Mac's function keys.

The application should have no traditional main window. Its primary interface lives in the macOS menu bar.

---

# 2. Product Vision

MacMode provides a single, fast control for switching the Mac between different usage profiles.

The long-term concept is:

```text
DEV
        ◄──────────────►
                    GAMING
```

Changing the mode may eventually modify multiple system behaviors.

For the MVP, only Function Key behavior is in scope.

Future capabilities may include:

* Function key behavior
* Power/performance profile
* Display configuration
* Audio configuration
* Focus / Do Not Disturb
* External monitor configuration
* Keyboard behavior
* Mouse/trackpad behavior
* Application-specific profiles
* Game-specific profiles
* Hardware-specific profiles

Do NOT implement future features unless explicitly requested.

---

# 3. Core UX

The application must live in the macOS menu bar.

Example:

```text
macOS Menu Bar
────────────────────────────────────────────

                [ 🎮 ]

                   │
                   ▼

        ┌─────────────────────────┐
        │                         │
        │        MacMode          │
        │                         │
        │  DEV ───────●── GAMING  │
        │                         │
        │  Function Keys          │
        │  ● Enabled              │
        │                         │
        │  ─────────────────────  │
        │                         │
        │  Settings               │
        │  Quit MacMode           │
        │                         │
        └─────────────────────────┘
```

The UI must be compact and suitable for a menu bar popover.

Avoid unnecessary navigation or screens.

The primary action should require one interaction.

---

# 4. Mode Model

Use an explicit domain model.

```swift
enum MacMode {
    case dev
    case gaming
}
```

Do not represent the application mode using arbitrary booleans such as:

```swift
isGaming
```

unless there is a compelling reason.

The mode should be the source of truth.

Recommended:

```swift
@Observable
final class ModeManager {
    private(set) var currentMode: MacMode

    func setMode(_ mode: MacMode)
}
```

The exact implementation may vary depending on the selected Swift/macOS versions.

---

# 5. Slider Behavior

The UI should visually present a slider:

```text
DEV ─────────────── GAMING
```

However, the domain model should remain discrete.

The slider is a UI representation of:

```text
DEV
GAMING
```

It must not introduce an undefined intermediate system state.

Recommended behavior:

```text
0.0 ───────── 0.5 ───────── 1.0
DEV                       GAMING
```

When the user crosses the midpoint, commit the corresponding mode.

Alternatively, a segmented control may be used if a slider produces poor native macOS UX.

The visual design should prioritize usability over blindly following the slider requirement.

---

# 6. MVP — Function Keys

The first system feature is Function Key behavior.

The application must provide a reliable mechanism to switch between the relevant macOS function-key configurations.

Before implementing this functionality, the agent MUST investigate the currently supported macOS APIs and determine:

1. How macOS stores the relevant Function Key preference.
2. Whether the preference can be modified programmatically.
3. Whether modification requires:

   * AppKit
   * CoreServices
   * IOKit
   * HID APIs
   * Core Graphics Event Services
   * Accessibility permission
   * Input Monitoring permission
   * another mechanism.
4. Whether the mechanism is supported on the target macOS versions.
5. Whether the mechanism is suitable for a third-party application.
6. Whether the mechanism survives application restart.
7. Whether the mechanism survives system restart.
8. Whether the mechanism affects all keyboards or only the current keyboard/device.

Do NOT guess an API.

If the preferred mechanism is undocumented/private or unreliable, document that fact and choose the safest supported alternative.

---

# 7. Function Key Abstraction

The rest of the application must not directly depend on low-level HID/Event APIs.

Create an abstraction.

Example:

```swift
protocol FunctionKeyController {

    var isStandardFunctionKeyModeEnabled: Bool { get }

    func enableStandardFunctionKeys() async throws

    func disableStandardFunctionKeys() async throws
}
```

The protocol is illustrative.

The implementation may differ if research shows that another abstraction is more appropriate.

The rest of the application should interact with:

```text
ModeManager
     │
     ▼
FeatureManager
     │
     ▼
FunctionKeyController
     │
     ▼
macOS
```

Never spread HID/Event/System Settings implementation details throughout SwiftUI views.

---

# 8. Mode → Feature Mapping

Use a feature-oriented architecture.

Example:

```swift
protocol SystemFeature {

    var identifier: String { get }

    func apply(for mode: MacMode) async throws
}
```

Then:

```text
FeatureManager
│
├── FunctionKeyFeature
│
├── PowerFeature          [future]
│
├── DisplayFeature        [future]
└── AudioFeature          [future]
```

For MVP:

```text
DEV
 └── Function Keys configuration

GAMING
 └── Function Keys configuration
```

The architecture must make adding another feature possible without modifying every existing component.

---

# 9. Application Architecture

Use a layered architecture.

```text
┌─────────────────────────────┐
│          SwiftUI            │
│                             │
│ MenuBarView                 │
│ ModeSlider                  │
│ SettingsView                │
└──────────────┬──────────────┘
               │
┌──────────────▼──────────────┐
│        Application          │
│                             │
│ ModeManager                 │
│ FeatureManager              │
└──────────────┬──────────────┘
               │
┌──────────────▼──────────────┐
│          Domain             │
│                             │
│ MacMode                     │
│ SystemFeature               │
│ FeatureState                │
└──────────────┬──────────────┘
               │
┌──────────────▼──────────────┐
│      System Integration     │
│                             │
│ FunctionKeyController       │
│ LaunchAtLogin                │
│ SystemPreferences            │
└─────────────────────────────┘
```

SwiftUI should never directly call low-level system APIs.

---

# 10. State Management

There should be one source of truth for the active mode.

Example:

```text
AppState
   │
   ├── currentMode
   ├── functionKeyState
   └── systemPermissionState
```

Avoid duplicated state such as:

```text
View says GAMING
ModeManager says DEV
System says DEV
```

After every successful mode change, all observable state must converge.

---

# 11. Persistence

Persist the user's selected mode.

The application should restore the last selected mode after restart.

Potential implementation:

```swift
UserDefaults
```

or SwiftUI:

```swift
@AppStorage
```

Do not create a database.

Persistence requirements:

```text
Application starts
      │
      ▼
Read saved mode
      │
      ▼
Validate system state
      │
      ▼
Synchronize if necessary
      │
      ▼
Show current mode
```

If the stored mode cannot be applied, the application must not silently claim success.

---

# 12. System State vs Application State

Distinguish:

```text
Desired State
```

from:

```text
Actual System State
```

Example:

```text
Desired:
GAMING

Actual:
DEV
```

This can happen if:

* the user changed the setting manually,
* another application changed it,
* macOS rejected the change,
* permissions changed,
* the API failed.

The UI must reflect actual state when known.

Do not silently overwrite the system state in response to external changes unless that behavior is explicitly designed.

---

# 13. Error Handling

System operations can fail.

Never do:

```swift
try? controller.enable()
```

for important system state changes.

Use explicit error handling.

Example:

```swift
do {
    try await controller.enableStandardFunctionKeys()
} catch {
    // update state
    // log
    // surface user-facing error
}
```

User-facing errors should be understandable.

Bad:

```text
Error: kIOReturnNotPermitted
```

Better:

```text
MacMode couldn't change the Function Key setting.

Check the required macOS permissions in System Settings
and try again.
```

The technical error should still be logged for debugging.

---

# 14. Permissions

Determine the minimum permissions required.

Do not request permissions speculatively.

The agent must research whether the selected implementation requires:

* Accessibility
* Input Monitoring
* Automation
* Full Disk Access
* privileged helper
* other entitlements.

Request only what is strictly necessary.

The application must explain why a permission is required before directing the user to System Settings.

Never attempt to bypass macOS security mechanisms.

---

# 15. Menu Bar Lifecycle

The application should:

* launch without opening a normal window,
* place an icon in the menu bar,
* display a popover when clicked,
* remain running while the popover is closed,
* provide a Quit action,
* optionally support Launch at Login.

The menu bar UI should be lightweight.

Avoid unnecessary background polling.

---

# 16. Launch at Login

Implement Launch at Login only after the MVP functionality works.

Use Apple's supported modern mechanism, such as the appropriate `ServiceManagement` API for the selected macOS target.

Do not implement a custom LaunchAgent unless there is a documented technical reason.

The user should be able to enable/disable:

```text
Launch MacMode at login
```

---

# 17. Performance

MacMode is a background utility.

Requirements:

* low CPU usage while idle,
* low memory usage,
* no unnecessary polling,
* no permanent high-frequency timers,
* no busy loops,
* no continuous HID scanning unless required,
* no network dependency.

The application should be effectively invisible when not being interacted with.

---

# 18. Logging

Use Apple's unified logging system.

Prefer:

```swift
import OSLog
```

Example:

```swift
private let logger = Logger(
    subsystem: "com.example.MacMode",
    category: "FunctionKeys"
)
```

Log:

* application startup,
* mode changes,
* system setting changes,
* permission problems,
* controller failures,
* synchronization failures.

Do not log:

* keyboard contents,
* typed text,
* passwords,
* personal data,
* unnecessary HID payloads.

---

# 19. Security & Privacy

MacMode must not collect user data.

No:

* analytics,
* telemetry,
* keyboard logging,
* network communication,
* cloud synchronization,
* account system.

The application only manipulates local macOS configuration required for its functionality.

If low-level keyboard APIs are used, they must only be used for the minimum required purpose.

Never record or persist actual keyboard input.

---

# 20. Testing

Testing is mandatory.

Minimum test layers:

## Unit Tests

Test:

```text
MacMode
ModeManager
FeatureManager
persistence
mode transitions
error handling
```

Example cases:

```text
DEV → GAMING
GAMING → DEV
DEV → DEV
GAMING → GAMING
failed transition
persistence restoration
```

## System Integration Tests

Where possible, test:

```text
FunctionKeyController
macOS system state
permission failure
system API failure
```

System tests may require a real macOS environment and cannot necessarily run in CI.

Document this explicitly.

---

# 21. Testability

Do not hard-code global system APIs directly into business logic.

Bad:

```swift
final class ModeManager {

    func enableGaming() {
        CGEvent.tapCreate(...)
    }
}
```

Prefer dependency injection:

```swift
final class ModeManager {

    private let functionKeys: FunctionKeyController

    init(functionKeys: FunctionKeyController) {
        self.functionKeys = functionKeys
    }
}
```

This allows tests to use:

```swift
MockFunctionKeyController
```

without modifying the actual Mac configuration.

---

# 22. Suggested Project Structure

Use a structure similar to:

```text
MacMode/
├── MacModeApp.swift
│
├── App/
│   ├── AppState.swift
│   └── AppDependencies.swift
│
├── UI/
│   ├── MenuBarView.swift
│   ├── ModeSelectorView.swift
│   ├── SettingsView.swift
│   └── Components/
│
├── Domain/
│   ├── MacMode.swift
│   ├── SystemFeature.swift
│   └── FeatureState.swift
│
├── Features/
│   ├── FeatureManager.swift
│   └── FunctionKeys/
│       ├── FunctionKeyFeature.swift
│       └── FunctionKeyController.swift
│
├── System/
│   ├── LaunchAtLogin.swift
│   └── SystemPermissions.swift
│
├── Infrastructure/
│   ├── Persistence/
│   └── Logging/
│
├── MacModeTests/
│
└── MacModeUITests/
```

Adapt the structure if the actual Xcode project benefits from a simpler organization.

Do not create directories purely for theoretical future functionality.

---

# 23. Technology Requirements

Use:

* Swift
* SwiftUI
* AppKit where necessary
* Apple's native frameworks
* Swift Concurrency where appropriate
* OSLog
* XCTest / Swift Testing depending on project configuration
* ServiceManagement for Launch at Login if required

Avoid:

* Electron
* Tauri
* React
* Node.js runtime
* Python runtime
* third-party keyboard drivers
* third-party system modification frameworks

unless research proves a native implementation cannot satisfy the requirement.

The application should be native.

---

# 24. macOS API Research Requirement

This is a critical requirement.

Before implementing Function Key control, research current Apple documentation and inspect the actual behavior of the target macOS version.

Do not rely solely on:

* old Stack Overflow answers,
* deprecated APIs,
* random GitHub projects,
* assumptions about System Settings internals.

Prefer:

1. Apple Developer Documentation
2. Apple Support documentation
3. current macOS behavior
4. source code of established open-source utilities as secondary evidence.

Record findings in:

```text
docs/research/function-keys.md
```

The document should contain:

```text
# Function Key Research

## Goal

What exactly MacMode needs to change.

## macOS behavior

How the setting works.

## Candidate APIs

API / Framework / Availability / Limitations

## Permissions

Required permissions and why.

## Chosen implementation

Why this approach was selected.

## Rejected approaches

What was considered and why it was rejected.

## Risks

Known compatibility or security concerns.
```

The agent MUST complete this research before locking the implementation architecture.

---

# 25. No Fake Implementations

Never create fake system integrations such as:

```swift
func enableFunctionKeys() {
    print("Function keys enabled")
}
```

and present them as complete.

If the real implementation is not known yet:

```text
1. research
2. document
3. implement
4. test
```

If macOS does not expose an appropriate supported API, explicitly document the limitation.

Do not hide the limitation behind a mock.

Mocks are allowed only inside tests.

---

# 26. Development Workflow

The agent should work incrementally.

Required sequence:

```text
Phase 1
↓
Inspect repository
↓
Phase 2
↓
Research macOS Function Key APIs
↓
Phase 3
↓
Create architecture
↓
Phase 4
↓
Implement Menu Bar MVP
↓
Phase 5
↓
Implement real Function Key integration
↓
Phase 6
↓
Persistence
↓
Phase 7
↓
Permissions/error handling
↓
Phase 8
↓
Tests
↓
Phase 9
↓
Build + verification
```

Do not implement everything in one giant change.

After each meaningful phase:

1. build,
2. run relevant tests,
3. inspect errors,
4. fix regressions,
5. continue.

---

# 27. Agent Behavior

The coding agent should behave as a senior macOS engineer.

Before changing code:

1. inspect the repository,
2. understand the existing architecture,
3. inspect package/project configuration,
4. identify the current macOS deployment target,
5. inspect existing tests,
6. research APIs when system behavior is involved.

Do not rewrite working code unnecessarily.

Do not introduce dependencies without justification.

Do not change architecture simply because another architecture is theoretically cleaner.

Prefer the smallest change that satisfies the specification.

---

# 28. Agent Research Policy

For external technical questions, research first.

Especially research before deciding:

* macOS API availability,
* entitlements,
* permissions,
* IOKit/HID behavior,
* Function Key behavior,
* Launch at Login,
* App Sandbox limitations,
* notarization requirements.

The agent should distinguish:

```text
FACT
```

from:

```text
ASSUMPTION
```

and:

```text
UNVERIFIED
```

If an implementation depends on an unverified assumption, stop and investigate it.

---

# 29. Verification

Before declaring the MVP complete, verify:

### Build

```text
xcodebuild build
```

using the actual project's scheme and destination.

### Tests

```text
xcodebuild test
```

using the actual project's scheme and destination.

Do not blindly copy these commands if the repository uses a different scheme/configuration.

### Static checks

Run available:

* Swift compiler diagnostics
* SwiftLint, if configured
* formatting checks, if configured

### Manual verification

On a real Mac:

```text
1. Launch MacMode.
2. Verify menu bar icon.
3. Open popover.
4. Verify current mode.
5. Switch DEV → GAMING.
6. Verify Function Key behavior.
7. Switch GAMING → DEV.
8. Verify Function Key behavior.
9. Quit application.
10. Relaunch application.
11. Verify persisted state.
12. Reboot if required by the selected system integration.
13. Verify behavior again.
```

---

# 30. Acceptance Criteria — MVP

The MVP is complete only when all of the following are true:

* [ ] Native macOS application.
* [ ] Runs as a menu bar utility.
* [ ] No unnecessary main window.
* [ ] Menu bar popover works.
* [ ] User can select DEV.
* [ ] User can select GAMING.
* [ ] Current mode is visually obvious.
* [ ] Mode persists between launches.
* [ ] Function Key behavior is controlled by the active mode.
* [ ] Real macOS system integration is used.
* [ ] No fake/mock system implementation in production.
* [ ] Errors are handled.
* [ ] Required permissions are clearly explained.
* [ ] No keyboard input is logged or collected.
* [ ] Unit tests exist for mode/domain logic.
* [ ] Integration/system behavior has been manually verified where automation is impossible.
* [ ] Project builds successfully.
* [ ] Tests pass.
* [ ] Technical limitations are documented.

---

# 31. Definition of Done

Do not declare the task complete because:

```text
"the code compiles"
```

The feature is complete only when:

```text
Specification
     ↓
Implementation
     ↓
Tests
     ↓
Real macOS verification
     ↓
Documentation
     ↓
Clean build
```

If real system behavior cannot be verified in the current environment, explicitly state:

```text
UNVERIFIED ON REAL MACOS
```

and explain exactly what remains to be tested.

---

# 32. Future Roadmap

Do not implement these during the MVP unless explicitly requested.

Potential future features:

### v0.2

* Launch at Login
* keyboard shortcut to switch mode
* animated mode transition
* improved menu bar icon
* notifications

### v0.3

* additional system features
* configurable profiles
* per-feature enable/disable

### v0.4

* application detection

Example:

```text
Xcode     → DEV
VSCode    → DEV
Steam     → GAMING
Game.app  → GAMING
```

### v1.0

* user-created profiles
* automatic profile switching
* external display profiles
* performance profiles
* per-game configuration

These are future requirements, not MVP requirements.

---

# 33. Engineering Principle

The most important principle of MacMode is:

> Make the smallest native macOS application possible while maintaining a clean abstraction around system-level behavior.

The UI should remain simple.

The complexity belongs behind well-defined system integration interfaces.

```text
Simple UI
   ↓
Simple domain model
   ↓
Explicit feature system
   ↓
Well-isolated macOS integration
```

Do not leak system-level complexity into the UI.

Do not sacrifice reliability for abstraction.

Do not sacrifice macOS compatibility for convenience.

---

# 34. First Agent Task

When the agent receives this specification, its first task is NOT to implement the entire application.

It must first:

1. Inspect the repository.
2. Determine whether an Xcode project already exists.
3. Determine the Swift version.
4. Determine the macOS deployment target.
5. Determine available build/test commands.
6. Research the Function Key system integration.
7. Create:

```text
docs/research/function-keys.md
```

8. Summarize the findings.
9. Propose the implementation plan.
10. Only then begin implementation.

Do not ask unnecessary questions if the repository and macOS documentation provide enough information.

If a decision materially affects permissions, compatibility, or architecture and cannot be resolved from available evidence, stop and ask the user before proceeding.

---

# 35. Final Rule

Never claim that MacMode changes macOS behavior unless the agent has verified that the underlying system behavior actually changes.

Correct:

```text
Function Key configuration successfully changed.
```

Only when verified.

Incorrect:

```text
Function Key configuration changed.
```

when the code merely attempted the operation.

Reliability is more important than apparent progress.

