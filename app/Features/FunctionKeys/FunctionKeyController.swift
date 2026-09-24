import Foundation
import IOKit
import IOKit.hid
import OSLog

/// Driver-level function-key mode. Matches the live `HIDFKeyMode` value:
/// `0` = media/special keys, `1` = standard function keys.
/// (Semantics confirmed against Fluor's `FKeyMode` + live `ioreg`.)
public enum FunctionKeyMode: Int, Codable, Sendable {
    case media = 0
    case function = 1
}

public enum FunctionKeyError: LocalizedError, Equatable {
    case serviceUnavailable
    case connectionFailed(code: Int32)
    case setFailed(code: Int32)
    case readFailed
    case verificationFailed(expected: FunctionKeyMode, actual: FunctionKeyMode)

    public var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "MacMode couldn't reach the keyboard driver."
        case .connectionFailed:
            return "MacMode couldn't open the keyboard driver."
        case .setFailed, .readFailed, .verificationFailed:
            return "MacMode couldn't change the Function Key setting."
        }
    }
}

/// Low-level contract. The rest of the app only sees `SystemFeature`.
public protocol FunctionKeyController: Sendable {
    func readMode() async throws -> FunctionKeyMode
    func applyMode(_ mode: FunctionKeyMode) async throws
}

/// Production controller: IOKit HID set (immediate) + global-preference
/// write (persistence) + best-effort Settings re-sync. Success is declared
/// only after a matching read-back — never on attempt alone.
public struct IOKitFunctionKeyStore: FunctionKeyController {
    private static let hidSystemPath = "IOService:/IOResources/IOHIDSystem"

    public init() {}

    public func readMode() async throws -> FunctionKeyMode {
        let entry = openHIDSystem()
        guard entry != 0 else { throw FunctionKeyError.serviceUnavailable }
        defer { IOObjectRelease(entry) }
        guard
            let prop = IORegistryEntryCreateCFProperty(entry, "HIDParameters" as CFString, kCFAllocatorDefault, 0),
            let dict = prop.takeRetainedValue() as? [String: Any],
            let raw = dict["HIDFKeyMode"] as? Int,
            let mode = FunctionKeyMode(rawValue: raw)
        else { throw FunctionKeyError.readFailed }
        return mode
    }

    public func applyMode(_ mode: FunctionKeyMode) async throws {
        try setHID(mode)
        PreferenceSync.writeStandardEnabled(mode == .function)
        await PreferenceSync.resyncSettingsUI()
        let back = try await readMode()
        guard back == mode else {
            AppLog.system.error("fn apply mismatch: wanted \(mode.rawValue), read \(back.rawValue)")
            throw FunctionKeyError.verificationFailed(expected: mode, actual: back)
        }
        AppLog.system.info("fn mode → \(mode.rawValue) (verified)")
    }

    // MARK: - IOKit

    private func openHIDSystem() -> io_registry_entry_t {
        var port: mach_port_t = 0
        guard IOMainPort(0, &port) == KERN_SUCCESS else { return 0 }
        return IORegistryEntryFromPath(port, Self.hidSystemPath)
    }

    private func setHID(_ mode: FunctionKeyMode) throws {
        let entry = openHIDSystem()
        guard entry != 0 else { throw FunctionKeyError.serviceUnavailable }
        defer { IOObjectRelease(entry) }
        var connect: io_connect_t = 0
        let krOpen = IOServiceOpen(entry, mach_task_self_, UInt32(kIOHIDParamConnectType), &connect)
        guard krOpen == KERN_SUCCESS else { throw FunctionKeyError.connectionFailed(code: krOpen) }
        defer { IOServiceClose(connect) }
        let krSet = IOHIDSetCFTypeParameter(connect, kIOHIDFKeyModeKey as CFString, mode.rawValue as CFNumber)
        guard krSet == KERN_SUCCESS else { throw FunctionKeyError.setFailed(code: krSet) }
    }
}

/// Keeps the persistent store (`com.apple.keyboard.fnState`) consistent
/// with the live driver state, and nudges Settings/daemons to re-read it.
enum PreferenceSync {
    private static let key = "com.apple.keyboard.fnState"
    private static let helperPath =
        "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"

    static func writeStandardEnabled(_ enabled: Bool) {
        let value: CFBoolean = enabled ? kCFBooleanTrue : kCFBooleanFalse
        CFPreferencesSetValue(
            key as CFString, value,
            kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost
        )
        CFPreferencesSynchronize(
            kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost
        )
    }

    /// Best-effort, never throws. The helper is private Apple tooling:
    /// gated on existence, failures only logged.
    static func resyncSettingsUI() async {
        guard FileManager.default.isExecutableFile(atPath: helperPath) else { return }
        await Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: helperPath)
            process.arguments = ["-u"]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            do { try process.run(); process.waitUntilExit() } catch {
                AppLog.system.error("activateSettings failed: \(String(describing: error))")
            }
        }.value
    }
}
