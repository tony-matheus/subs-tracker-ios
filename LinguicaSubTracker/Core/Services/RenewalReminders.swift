import Foundation
import os
import UserNotifications

/// Local "Netflix renews tomorrow" notifications for recurring expenses.
///
/// Device-local on purpose: every device schedules from its own copy of the
/// (synced) data, and the on/off + lead time live in `.standard`, not in the
/// synced `AppSettings`.
@MainActor
final class RenewalReminders: NSObject, UNUserNotificationCenterDelegate {
    static let enabledKey = "renewal_reminders_enabled"
    static let leadDaysKey = "renewal_lead_days"
    static let leadDayOptions = [0, 1, 3]
    private static let idPrefix = "renewal-"
    private static let log = Logger(subsystem: "Satoru", category: "Reminders")

    struct Reminder: Equatable {
        let id: String
        let expense: Expense
        let chargeDate: Date
        let fireDate: Date
        let leadDays: Int
    }

    private let store: AppStore
    private let settingsStore: SettingsStore
    private weak var coordinator: AppCoordinator?
    private let center = UNUserNotificationCenter.current()
    private var rescheduleTask: Task<Void, Never>?

    init(store: AppStore, settingsStore: SettingsStore, coordinator: AppCoordinator) {
        self.store = store
        self.settingsStore = settingsStore
        self.coordinator = coordinator
        super.init()
        center.delegate = self
    }

    var isEnabled: Bool { UserDefaults.standard.bool(forKey: Self.enabledKey) }
    var leadDays: Int { UserDefaults.standard.object(forKey: Self.leadDaysKey) as? Int ?? 1 }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// Turning on asks for permission. Returns false when permission is denied.
    @discardableResult
    func setEnabled(_ on: Bool) async -> Bool {
        UserDefaults.standard.set(on, forKey: Self.enabledKey)
        if on {
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            if !granted {
                UserDefaults.standard.set(false, forKey: Self.enabledKey)
                return false
            }
        }
        reschedule()
        return true
    }

    /// Replaces every pending renewal notification with a fresh plan. Called
    /// on every expense change and app activation; the latest call wins.
    func reschedule() {
        rescheduleTask?.cancel()
        let expenses = store.expenses
        let settings = settingsStore.settings
        rescheduleTask = Task {
            let stale = await center.pendingNotificationRequests()
                .map(\.identifier).filter { $0.hasPrefix(Self.idPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: stale)

            guard FeatureFlags.renewals, isEnabled else { return }
            let status = await authorizationStatus()
            guard status == .authorized || status == .provisional else { return }

            for reminder in Self.plan(expenses: expenses, now: .now, leadDays: leadDays) {
                guard !Task.isCancelled else { return }
                try? await center.add(Self.request(for: reminder, settings: settings))
            }
        }
    }

    // MARK: - Planning (pure, tested)

    /// Upcoming renewals as reminders, soonest first. Capped below iOS's
    /// 64-pending-notifications limit; later renewals get scheduled on a
    /// later reschedule (every app open).
    static func plan(
        expenses: [Expense],
        now: Date,
        leadDays: Int,
        hour: Int = 9,
        horizonDays: Int = 62,
        limit: Int = 60,
        calendar: Calendar = .current
    ) -> [Reminder] {
        let recurring = expenses.filter { $0.billingCycle != .oneTime }
        let start = calendar.startOfDay(for: now)
        guard let end = calendar.date(byAdding: .day, value: horizonDays, to: start) else { return [] }

        let reminders = ExpenseService.occurrences(in: DateInterval(start: start, end: end), recurring)
            .compactMap { hit -> Reminder? in
                guard let day = calendar.date(byAdding: .day, value: -leadDays, to: hit.date),
                      let fire = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day),
                      fire > now
                else { return nil }
                return Reminder(
                    id: "\(idPrefix)\(hit.expense.id.uuidString)-\(Int(hit.date.timeIntervalSince1970))",
                    expense: hit.expense,
                    chargeDate: hit.date,
                    fireDate: fire,
                    leadDays: leadDays
                )
            }
            .sorted { $0.fireDate < $1.fireDate }
        return Array(reminders.prefix(limit))
    }

    static func title(for reminder: Reminder) -> String {
        let name = reminder.expense.name
        switch reminder.leadDays {
        case 0: return "\(name) renews today"
        case 1: return "\(name) renews tomorrow"
        default: return "\(name) renews in \(reminder.leadDays) days"
        }
    }

    private static func request(for reminder: Reminder, settings: AppSettings) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title(for: reminder)
        content.body = "\(MoneyFormatter.format(reminder.expense.price, settings: settings)) · \(reminder.expense.category)"
        content.sound = .default
        content.userInfo = ["url": DeepLink.day(reminder.chargeDate).url.absoluteString]
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.fireDate)
        return UNNotificationRequest(
            identifier: reminder.id,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    /// Tapping a reminder opens that renewal's day in the app.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let raw = response.notification.request.content.userInfo["url"] as? String,
              let url = URL(string: raw) else { return }
        await MainActor.run { coordinator?.handle(url) }
    }

    #if DEBUG
    /// `SIMCTL_CHILD_DEBUG_REMINDERS=1`: turns reminders on, reschedules, and
    /// fires the first planned one 5 seconds from now so it can be seen.
    func debugRun() async {
        guard await setEnabled(true) else { return Self.log.info("debug: permission denied") }
        let settings = settingsStore.settings
        if let first = Self.plan(expenses: store.expenses, now: .now, leadDays: leadDays).first {
            let content = Self.request(for: first, settings: settings).content
            try? await center.add(UNNotificationRequest(
                identifier: "debug-renewal", content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            ))
        }
        try? await Task.sleep(for: .seconds(1))
        let pending = await center.pendingNotificationRequests()
        Self.log.info("debug: \(pending.count) pending, first: \(pending.first?.content.title ?? "-")")
    }
    #endif
}
