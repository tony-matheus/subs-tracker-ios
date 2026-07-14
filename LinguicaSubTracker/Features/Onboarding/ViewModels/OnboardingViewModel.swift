import Foundation
import Observation

enum OnboardingPage: Int, CaseIterable {
    // case welcome // hidden with the mascot core elements
    case calendar
    case budget
    case organize
    case stats
    case choosePath
    case quickAdd

    var isLast: Bool { self == OnboardingPage.allCases.last }
}

@Observable
@MainActor
final class OnboardingViewModel {
    var page: OnboardingPage = .calendar
    /// Set before `page` mutates so the liquid ripple anchors on the
    /// correct edge for forward vs. backward navigation.
    private(set) var movingForward = true

    var drafts: [OnboardingDraft] = [OnboardingDraft()]

    let store: AppStore
    let settingsStore: SettingsStore

    init(store: AppStore, settingsStore: SettingsStore) {
        self.store = store
        self.settingsStore = settingsStore
        #if DEBUG
        // Jump straight to a page for screenshot/UI testing:
        // SIMCTL_CHILD_ONBOARDING_PAGE=<0-5> simctl launch …
        if let raw = ProcessInfo.processInfo.environment["ONBOARDING_PAGE"],
           let value = Int(raw),
           let override = OnboardingPage(rawValue: value) {
            page = override
        }
        #endif
    }

    var validDrafts: [OnboardingDraft] { drafts.filter(\.isValid) }

    func next() {
        guard let next = OnboardingPage(rawValue: page.rawValue + 1) else { return }
        movingForward = true
        page = next
    }

    func back() {
        guard let previous = OnboardingPage(rawValue: page.rawValue - 1) else { return }
        movingForward = false
        page = previous
    }

    func go(to destination: OnboardingPage) {
        guard destination != page else { return }
        movingForward = destination.rawValue > page.rawValue
        page = destination
    }

    func addDraft() {
        drafts.append(OnboardingDraft())
    }

    func removeDraft(id: UUID) {
        guard drafts.count > 1 else { return }
        drafts.removeAll { $0.id == id }
    }

    /// Persists every valid draft through the existing store pipeline.
    /// Schedule defaults to monthly; category/list use the model defaults.
    func commit() {
        for draft in validDrafts {
            store.add(
                Expense(
                    name: draft.name.trimmingCharacters(in: .whitespaces),
                    price: draft.price,
                    billingCycle: .monthly,
                    startDate: draft.startDate
                )
            )
        }
    }
}
