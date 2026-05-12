import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class SubscriptionInDayViewModel {
    var showAddSheet = false

    let date: Date
    let store: AppStore
    let coordinator: AppCoordinator

    init(date: Date, store: AppStore, coordinator: AppCoordinator) {
        self.date = date
        self.store = store
        self.coordinator = coordinator
    }

    var subscriptions: [Subscription] {
        SubscriptionService.subscriptions(for: date, subs: store.subscriptions)
    }

    var total: Double {
        subscriptions.reduce(0) { $0 + $1.price }
    }

    var compactHeight: CGFloat {
        let rowH: CGFloat = 56
        let rows = CGFloat(subscriptions.count + 1)
        let totalBlock: CGFloat = 72
        let chrome: CGFloat = 25 + 58 + 12 + 12 + 24
        return min(chrome + rows * rowH + totalBlock, 520)
    }

    func selectSubscription(_ sub: Subscription) {
        // Dismiss the day sheet first; HomeView owns the summary sheet so we
        // delay its presentation until the day-sheet dismiss animation completes.
        coordinator.selectedDay = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [coordinator] in
            coordinator.selectedSubscription = sub
        }
    }

    func rowSubtitle(for sub: Subscription) -> String {
        let schedule = sub.schedule.rawValue.capitalized
        let price = sub.price.formatted(.currency(code: "CAD"))
        return "\(schedule) • \(price)"
    }

    /// "Delete current" — stop the subscription from this day onward by
    /// setting `endDate` to the day before `self.date`. Past months stay
    /// historical; this day and future months disappear.
    func deleteFromCurrentDay(_ sub: Subscription) {
        let calendar = Calendar.current
        let dayBefore = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: date))
            ?? calendar.startOfDay(for: date)
        var updated = sub
        updated.endDate = dayBefore
        store.update(updated)
    }

    /// "Delete all" — remove the subscription entirely.
    func deleteAll(_ sub: Subscription) {
        store.delete(sub)
    }
}
