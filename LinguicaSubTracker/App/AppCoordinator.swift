import Foundation
import SwiftUI
import Observation

struct SubscriptionFilter: Equatable {
    var list: String?
    var category: String?
    var paymentMethod: String?

    static let all = SubscriptionFilter()

    var isActive: Bool { list != nil || category != nil || paymentMethod != nil }

    var activeNames: [String] {
        [list, category, paymentMethod].compactMap { $0 }
    }
}

@Observable
@MainActor
final class AppCoordinator {
    var selectedDay: Date?
    var selectedSubscription: Subscription?
    var filter: SubscriptionFilter = .all

    func filtered(_ subs: [Subscription]) -> [Subscription] {
        subs.filter { sub in
            if let list = filter.list, sub.list != list { return false }
            if let category = filter.category, sub.category != category { return false }
            if let payment = filter.paymentMethod, sub.paymentMethod != payment { return false }
            return true
        }
    }

    func selectedDayBinding() -> Binding<Bool> {
        Binding(
            get: { self.selectedDay != nil },
            set: { if !$0 { self.selectedDay = nil } }
        )
    }

    func selectedSubscriptionBinding() -> Binding<Bool> {
        Binding(
            get: { self.selectedSubscription != nil },
            set: { if !$0 { self.selectedSubscription = nil } }
        )
    }
}
