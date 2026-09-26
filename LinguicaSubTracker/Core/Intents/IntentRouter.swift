import Foundation
import Observation

/// Hand-off from App Intents that open the app (Quick Add control, Visual
/// Intelligence) to the UI. Registered with `AppDependencyManager` in the app;
/// compiled into the widget extension only so shared intents type-check —
/// those intents always run in the app process.
@Observable
@MainActor
final class IntentRouter {
    /// Set by `QuickAddIntent`; the app root shows the voice capture.
    var pendingQuickAdd = false
    /// Set by `OpenReceiptCaptureIntent`; the app root shows that receipt's
    /// review. An id (not the items) so this file needs no receipt types.
    var pendingReceiptID: UUID?
}
