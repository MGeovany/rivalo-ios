import Foundation
import UserNotifications

/// An app-routing intent emitted when the user taps a match notification/action.
struct MatchOpenEvent: Equatable, Sendable {
    let sessionId: String
    /// True when the user chose "Add result" (open the result form directly).
    let openResult: Bool
}

/// Local notifications for the post-match flow: a summary notification when
/// an activity finishes, plus a later reminder to add the result if it wasn't
/// filled. Degrades gracefully when permission is denied.
final class MatchNotifications: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = MatchNotifications()

    // Category / action identifiers.
    static let summaryCategory = "MATCH_SUMMARY"
    static let reminderCategory = "MATCH_RESULT_REMINDER"
    static let openSummaryAction = "OPEN_SUMMARY"
    static let addResultAction = "ADD_RESULT"

    /// Default delay before the "add result" reminder fires.
    static let reminderDelay: TimeInterval = 2 * 60 * 60

    private let stream: AsyncStream<MatchOpenEvent>
    private let continuation: AsyncStream<MatchOpenEvent>.Continuation

    override init() {
        var cont: AsyncStream<MatchOpenEvent>.Continuation!
        stream = AsyncStream { cont = $0 }
        continuation = cont
        super.init()
    }

    /// Stream of open-intents from tapped notifications (single consumer).
    func events() -> AsyncStream<MatchOpenEvent> { stream }

    /// Wires the delegate, registers categories and requests authorization. Call once at launch.
    func bootstrap() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        let openSummary = UNNotificationAction(identifier: Self.openSummaryAction, title: "View summary", options: [.foreground])
        let addResult = UNNotificationAction(identifier: Self.addResultAction, title: "Add result", options: [.foreground])
        let summary = UNNotificationCategory(identifier: Self.summaryCategory, actions: [openSummary, addResult], intentIdentifiers: [], options: [])
        let reminder = UNNotificationCategory(identifier: Self.reminderCategory, actions: [addResult], intentIdentifiers: [], options: [])
        center.setNotificationCategories([summary, reminder])

        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private static func reminderID(_ sessionId: String) -> String { "result-reminder-\(sessionId)" }

    /// Posts an immediate summary notification for a finished session.
    func scheduleSummary(sessionId: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = Self.summaryCategory
        content.userInfo = ["sessionId": sessionId]
        let request = UNNotificationRequest(identifier: "summary-\(sessionId)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    /// Schedules the "add result" reminder unless one is already pending for this session.
    func scheduleResultReminder(sessionId: String, after delay: TimeInterval = MatchNotifications.reminderDelay) {
        let content = UNMutableNotificationContent()
        content.title = "How did it go?"
        content.body = "Add the result of your match — who you played and the score."
        content.sound = .default
        content.categoryIdentifier = Self.reminderCategory
        content.userInfo = ["sessionId": sessionId]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(60, delay), repeats: false)
        let request = UNNotificationRequest(identifier: Self.reminderID(sessionId), content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Cancels a pending result reminder (called once the result is saved).
    func cancelResultReminder(sessionId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.reminderID(sessionId)])
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }
        guard let sessionId = response.notification.request.content.userInfo["sessionId"] as? String else { return }
        let openResult: Bool
        switch response.actionIdentifier {
        case Self.addResultAction:
            openResult = true
        case Self.openSummaryAction, UNNotificationDefaultActionIdentifier:
            // Default tap on a reminder opens the result form; on a summary opens the summary.
            openResult = response.notification.request.content.categoryIdentifier == Self.reminderCategory
        case UNNotificationDismissActionIdentifier:
            return
        default:
            openResult = false
        }
        continuation.yield(MatchOpenEvent(sessionId: sessionId, openResult: openResult))
    }
}
