import Foundation
import os

enum ProfilePhotoLog {
    private static let log = Logger(subsystem: "com.mgeovany.rivalo", category: "ProfilePhoto")

    static func info(_ message: String) {
        log.info("\(message, privacy: .public)")
    }

    static func debug(_ message: String) {
        log.debug("\(message, privacy: .public)")
    }

    static func error(_ message: String) {
        log.error("\(message, privacy: .public)")
    }
}
