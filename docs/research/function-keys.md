# Function Key Research

Date: 2026-09-24. Host: macOS 27.0 (26A428), arm64, Xcode 27.0, Swift 6.4.
Labels used below: **FACT** (verified on this machine or in source read
directly), **ASSUMPTION** (reasonable but unproven), **UNVERIFIED** (must be
tested before claiming it works).

## Goal

MacMode MVP must switch the "Use F1, F2, etc. keys as standard function
keys" behavior (System Settings → Keyboard → Keyboard Shortcuts →
Function Keys) between two profiles:

* DEV → standard function keys (F1 = F1, for IDEs/debuggers).
* GAMING → media/special keys (F1 = brightness, no Fn required).

The DEV→function / GAMING→media mapping is a proposal (the obvious
interpretation); flipping it later is a one-line mapping change.

## macOS behavior (FACT)

1. Global preference `com.apple.keyboard.fnState` exists in
   `NSGlobalDomain`, stored in `~/Library/Preferences/.GlobalPreferences.plist`.
   Current value on this Mac: `true` (= standard function keys ON).
   Verified: `defaults read -g com.apple.keyboard.fnState` → `1`;
   `PlistBuddy` on `.GlobalPreferences.plist` → `true`.
2. Live driver state `HIDFKeyMode` is present in `HIDEventServiceProperties`
   on HID event services (`ioreg -l`): currently `1` on all services.
   Semantics from Fluor source (`FKeyMode` enum): `0` = media/special keys,
   `1` = standard function keys. Consistent with (1).
3. Keyboards on this Mac (`hidutil list`): internal
   (`AppleHIDKeyboardEventDriverV2`) + Bluetooth Magic Keyboard
   (`0x4c:0x322`, `AppleHIDKeyboardEventDriverV2` over Bluetooth).
4. There is **no public Apple API** for this toggle. Apple Developer
   Documentation has no symbol for it; the setting is owned by
   System Settings → Keyboard. (FACT: searched docs; absence verified to
   the extent searchable.)
5. Writing the plist alone does NOT apply live. Known since at least 2013
   (cfprefsd caching; Stack Overflow 16913018): the write lands in the
   plist but neither the HID driver nor the Settings UI picks it up
   without a nudge or relogin.

## Candidate APIs

### A. IOKit HID direct set (PRIMARY — selected)

* Framework: `IOKit` (`IOHIDLib`), all **public** APIs.
* Mechanism (FACT — read in Fluor source,
  `Pyroh/Fluor`, `Fluor/Misc/FKeyManager.swift`, MIT):
  ```text
  IOMasterPort → IORegistryEntryFromPath("IOService:/IOResources/IOHIDSystem")
    → IOServiceOpen(kIOHIDParamConnectType)
    → IOHIDSetCFTypeParameter(connect, kIOHIDFKeyModeKey, CFNumber(0|1))
  ```
  Read-back: `HIDParameters` → `HIDFKeyMode` on the registry entry.
* Limitations: `IOMasterPort` is deprecated (use `IOMainPort` in new code);
  Fluor targets the Intel/macOS-11 era. Operates on the HID system
  singleton (global effect, not per-keyboard selection in Fluor's usage).
* Availability: IOKit HID user client APIs exist on all macOS versions we
  care about (deployment target 14.0 proposed — ancient API, no concern).

### B. Global defaults + private re-sync helper (FALLBACK / COMPLEMENT)

* Mechanism (FACT — verified commands on this Mac):
  ```bash
  defaults write -g com.apple.keyboard.fnState -bool true|false
  /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  ```
* Verified 2026-09-24: write 1→0→1 works, reads confirm, helper exists
  (`-rwxr-xr-x root wheel`), runs as user without sudo, exits 0 in ~0.2s.
  Machine left at original value (`1`).
* Used in the wild by `Chromeox/fn-toggle` ("applies live, no logout")
  and SoundFlow scripts (secondary evidence, inspected).
* Limitations: `activateSettings` is **private** (unsupported; could vanish
  or change behavior in any release). Gate its use on file-existence and
  fall back to telling the user a relogin may be needed.

### C. Native write without `defaults(1)` (for production code)

* `CFPreferencesSetValue(kCFPreferencesAnyApplication,
  "com.apple.keyboard.fnState", ...)` + `CFPreferencesSynchronize`.
  Public CoreFoundation API; same store as B without shelling out.
  (ASSUMPTION: equivalent effect to `defaults write`. Trivially testable
  in Phase 3.)

## Permissions (FACT + UNVERIFIED)

* FACT: paths A (IOKit user client from unsandboxed app) and B/C (own
  global prefs) require **no special permission on paper** — no
  Accessibility, no Input Monitoring, no entitlement, no sudo (verified:
  both probes ran unprivileged).
* UNVERIFIED: whether `IOServiceOpen(..., kIOHIDParamConnectType)` on
  `IOHIDSystem` still succeeds on macOS 27 unsandboxed. Phase 3 opens with
  a tiny harness test: open → set → read-back. If it returns
  `kIOReturnNotPermitted`, document and fall back to B/C.
* MacMode will NOT use keyboard event taps (would demand Accessibility and
  violate the no-keystroke-logging rule) and never inspects keystrokes.

## Chosen implementation

`FunctionKeyController` (protocol, per SPEC §7) with a production type
that does, in order, per transition:

1. `IOHIDSetCFTypeParameter(kIOHIDFKeyModeKey)` — immediate driver effect.
2. `CFPreferences` write of `com.apple.keyboard.fnState` — persistence
   across restart (the store Settings itself reads).
3. `activateSettings -u` if present — re-sync Settings UI/daemons.
4. Read-back (`HIDFKeyMode` + `fnState`); report success only if reads
   match the desired mode. Otherwise throw a typed error with a
   user-facing message ("couldn't change… check permissions… try again").

Why both A and B: A gives immediacy + verifiability, B gives persistence;
neither alone is proven sufficient on macOS 27. If A fails at runtime,
degrade to B-only and surface it (no silent fake success).

Deployment target: **macOS 14.0** (proposed; `@Observable`, modern
`ServiceManagement`, and all IOKit symbols used are far older).

## Rejected approaches

* AppleScript-clicking System Settings: fragile across releases, needs
  Automation permission, flashes GUI. Rejected.
* `defaults write` alone: proven (2013→today) to not apply live. Rejected
  as sole mechanism; kept only as the persistence half of B/C.
* CGEvent/keyboard taps to *effect* the change: cannot change the setting
  at all; needs Accessibility; privacy-hostile. Rejected.
* Private HID/kernel APIs, kexts: impossible/unsupported on modern macOS.
  Rejected.
* Per-app auto-switching (Fluor-style): roadmap v1.0 scope, not MVP.
  Deferred, architecture must not preclude it.

## Risks

1. **Live-apply on macOS 27 UNVERIFIED.** `activateSettings -u` ran clean
   but behavioral proof (pressing F1/F2) requires a human key press.
   → Phase 4 manual verification (user presses keys per SPEC §29).
2. **IOKit user-client lock-down UNVERIFIED.** If `IOServiceOpen` fails,
   MVP still ships on path B/C with degraded immediacy. Test first in
   Phase 3.
3. **Bluetooth reconnect may reset the external keyboard's mode**
   (ASSUMPTION). MVP handles internal + external at switch time; re-apply
   on wake/reconnect is future scope — document if observed.
4. **Settings UI sync is cosmetic.** Read-back is source of truth, not the
   checkbox pixel state.
5. **`activateSettings` is private.** Existence-gated; never a hard
   dependency.
6. **Internal vs external divergence UNVERIFIED.** This Mac has both;
   Phase 4 must check F-keys on each after a switch.
7. Mode↔setting mapping (DEV=function) is a product default, reversible.

## Polarity under investigation (2026-09-24, UNVERIFIED)

User reports inverted behavior with pristine presets: DEV selected →
F1 gives brightness; GAMING selected → F1 acts as F1. Live stores at
report time: `fnState=0`, `HIDFKeyMode=0` on all services, app selection
`DEV` (selectedID = dev UUID) with a legacy `currentMode=gaming` key —
i.e. desired=DEV while system holds GAMING's values (delete-fallback or
unapplied switch; the UI correctly shows it unconfirmed).

Two live hypotheses, both consistent with parts of the evidence:

* H1 — HID polarity flipped on macOS 27: `0`=standard, `1`=media
  (opposite of Fluor's 2020 `FKeyMode`). Fits the report perfectly if both
  applies succeeded with read-back match.
* H2 — normal polarity; the DEV apply never took effect (selection vs
  system confusion) and the GAME observation needs retesting under a
  controlled protocol.

Decisive tests (need the human + real keys, cannot be automated here):

1. At the current `0/0` state, press F1 (no Fn): brightness ⇒ H2
   territory (`0`=media, normal); F1-action ⇒ H1 (flipped).
2. Read the Settings checkbox state at `fnState=0`: OFF ⇒ normal
   (`false`=media); ON ⇒ the boolean mapping is inverted too.

Do NOT change the mapping until (1) and (2) answer. If H1 wins, swap the
interpretation at the IOKit boundary (explicit map, NOT raw-value swap:
`FunctionKeyMode` raw values are already persisted in user libraries).

## Test plan hooks (for Phase 3/4)

* Unit: `ModeManager` transitions, `FeatureManager` fan-out,
  persistence round-trip, error mapping — all with
  `MockFunctionKeyController` (no system touch).
* Harness (throwaway, not shipped): IOKit open/set/read-back on this Mac.
* Manual (SPEC §29): switch DEV→GAMING→DEV, press physical F-keys on
  internal + Magic Keyboard, relaunch (persistence), reboot (survival),
  deny-permission paths if any permission proves necessary.
