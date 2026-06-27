import Foundation

/// A minimal expense draft collected during onboarding — just the
/// essentials; everything else falls back to `Expense` defaults.
struct OnboardingDraft: Identifiable, Equatable {
    let id = UUID()
    var name: String = ""
    var price: Double = 0
    var startDate: Date = .now

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && price > 0
    }
}
