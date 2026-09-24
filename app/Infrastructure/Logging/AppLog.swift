import Foundation
import OSLog

/// Centralized loggers. Never log keystrokes, typed text, or personal data.
public enum AppLog {
    public static let subsystem = "app.macmode"
    public static let app = Logger(subsystem: subsystem, category: "app")
    public static let modes = Logger(subsystem: subsystem, category: "modes")
    public static let system = Logger(subsystem: subsystem, category: "system")
}
