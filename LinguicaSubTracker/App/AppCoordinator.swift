import Foundation
import SwiftUI
import Observation

struct ExpenseFilter: Equatable {
    var list: String?
    var category: String?
    var paymentMethod: String?

    static let all = ExpenseFilter()

    var isActive: Bool { list != nil || category != nil || paymentMethod != nil }

    var activeNames: [String] {
        [list, category, paymentMethod].compactMap { $0 }
    }
}

@Observable
@MainActor
final class AppCoordinator {
    var selectedDay: Date?
    var selectedExpense: Expense?
    var filter: ExpenseFilter = .all

    /// Flipped by Settings' "Reset App" flow after wiping all data;
    /// the app root observes this to bring back the onboarding flow.
    var didRequestOnboardingReplay = false

    func filtered(_ expenses: [Expense]) -> [Expense] {
        expenses.filter { expense in
            if let list = filter.list, expense.list != list { return false }
            if let category = filter.category, expense.category != category { return false }
            if let payment = filter.paymentMethod, expense.paymentMethod != payment { return false }
            return true
        }
    }

    func selectedDayBinding() -> Binding<Bool> {
        Binding(
            get: { self.selectedDay != nil },
            set: { if !$0 { self.selectedDay = nil } }
        )
    }

    func selectedExpenseBinding() -> Binding<Bool> {
        Binding(
            get: { self.selectedExpense != nil },
            set: { if !$0 { self.selectedExpense = nil } }
        )
    }
}
