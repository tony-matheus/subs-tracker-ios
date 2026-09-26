#if FF_QUICK_ADD
import AppIntents
import Foundation

/// Opens Satoru straight into voice capture. Backs the Control Center /
/// Lock Screen / Action Button control; shared with the widget extension so
/// the control can reference it, but it always runs in the app.
struct QuickAddIntent: AppIntent {
    static let title: LocalizedStringResource = "Speak an Expense"
    static let description = IntentDescription(
        "Opens Satoru listening, so you can say what you spent.",
        categoryName: "Transactions"
    )
    static let supportedModes: IntentModes = .foreground

    @Dependency private var router: IntentRouter

    @MainActor
    func perform() async throws -> some IntentResult {
        router.pendingQuickAdd = true
        return .result()
    }
}
#endif
