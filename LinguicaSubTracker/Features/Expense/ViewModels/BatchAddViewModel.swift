import Foundation
import Observation

/// "Add Multiple" hub flow: a multi-row draft table (same shape as the
/// onboarding quick-add) saving every valid row as a one-time expense.
@Observable
@MainActor
final class BatchAddViewModel {
    var drafts: [OnboardingDraft]

    let store: AppStore
    let settingsStore: SettingsStore

    init(date: Date, store: AppStore, settingsStore: SettingsStore) {
        self.store = store
        self.settingsStore = settingsStore
        self.drafts = [OnboardingDraft(startDate: date)]
    }

    var validDrafts: [OnboardingDraft] { drafts.filter(\.isValid) }

    func addDraft() {
        // New rows default to the last row's date — bursts are same-day.
        drafts.append(OnboardingDraft(startDate: drafts.last?.startDate ?? .now))
    }

    func removeDraft(id: UUID) {
        guard drafts.count > 1 else { return }
        drafts.removeAll { $0.id == id }
    }

    /// Persists every valid draft as a one-time expense through `AppStore.add`.
    func commit() {
        for draft in validDrafts {
            store.add(
                Expense(
                    name: draft.name.trimmingCharacters(in: .whitespaces),
                    price: draft.price,
                    billingCycle: .oneTime,
                    type: .expense,
                    // Start-of-day so the calendar cell matches (see ExpenseFormViewModel).
                    startDate: Calendar.current.startOfDay(for: draft.startDate),
                    list: "Personal"
                )
            )
        }
    }
}
