import Foundation

enum SubscriptionFormMode {
    case create(template: SubscriptionTemplate, date: Date)
    case createBlank(name: String, date: Date)
    case edit(Subscription)
}
