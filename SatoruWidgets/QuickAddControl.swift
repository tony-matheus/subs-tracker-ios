#if FF_QUICK_ADD
import AppIntents
import SwiftUI
import WidgetKit

/// Control Center, Lock Screen and Action Button: one press opens Satoru
/// listening for an expense.
struct QuickAddControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "QuickAdd") {
            ControlWidgetButton(action: QuickAddIntent()) {
                Label("Speak an Expense", systemImage: "mic.fill")
            }
        }
        .displayName("Speak an Expense")
        .description("Open Satoru listening, then say what you spent.")
    }
}
#endif
