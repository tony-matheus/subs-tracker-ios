import Foundation

enum ExpenseFormMode {
    case create(template: SubscriptionTemplate, date: Date)
    case createBlank(name: String, date: Date)
    case edit(Expense)
}
