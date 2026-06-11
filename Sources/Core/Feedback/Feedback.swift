import AudioToolbox
import UIKit

/// Centralized haptic + sound cues. Sounds are short, quiet system sounds
/// (no bundled assets) and respect the ring/silent switch.
@MainActor
enum Feedback {
    // MARK: - Haptics

    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func press() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    // MARK: - Sounds

    enum Sound: SystemSoundID {
        /// Soft "tink" used for confirmations.
        case tick = 1057
        /// Begin-recording cue used when a match starts.
        case beginMatch = 1113
        /// End-recording cue used when a match finishes.
        case endMatch = 1114
    }

    static func play(_ sound: Sound) {
        AudioServicesPlaySystemSound(sound.rawValue)
    }

    // MARK: - Composite cues

    /// Kicking off a match: strong haptic + start cue.
    static func matchStart() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        play(.beginMatch)
    }

    /// Match finished: success haptic + end cue.
    static func matchEnd() {
        success()
        play(.endMatch)
    }

    /// Saved / confirmed: success haptic + soft tick.
    static func confirm() {
        success()
        play(.tick)
    }
}
