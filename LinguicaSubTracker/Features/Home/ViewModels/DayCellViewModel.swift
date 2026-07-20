import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class DayCellViewModel {
    let store: AppStore
    var expenses: [Expense]
    var status: DayStatus
    var date: Date?

    init(store: AppStore, date: Date?, status: DayStatus, expenses: [Expense]) {
        self.store = store
        self.date = date
        self.status = status
        self.expenses = expenses
    }

    var primaryExpense: Expense? { expenses.first }
    var secondaryExpense: Expense? { expenses.last }
    var primaryCustomization: LogoCustomization? {
        primaryExpense?.logoCustomization(in: store)
    }
    var primaryColor: Color? { primaryCustomization?.resolvedBackground }
    var overflowCount: Int { max(0, expenses.count - 2) }
    var displayDay: Bool { status != .none }
    var dayNumber: Int? {
        guard let date else { return nil }
        return Calendar.current.component(.day, from: date)
    }
}
