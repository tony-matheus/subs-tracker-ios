import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class SubscriptionSummaryViewModel {
    var showDeleteAlert = false
    var showEdit = false
    var isActive: Bool

    let subscription: Subscription
    let store: AppStore
    let coordinator: AppCoordinator

    init(subscription: Subscription, store: AppStore, coordinator: AppCoordinator) {
        self.subscription = subscription
        self.store = store
        self.coordinator = coordinator
        self.isActive = subscription.isActive
    }

    var themeColor: Color { customization.resolvedBackground }

    var nextPaymentText: String {
        guard let next = SubscriptionService.nextPayment(for: subscription) else {
            return "—"
        }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: next).day ?? 0
        let formatted = next.formatted(.dateTime.day().month(.wide))
        return "\(formatted) (in \(days) days)"
    }

    var totalSpent: Double {
        SubscriptionService.totalSpent(for: subscription)
    }

    var scheduleAndPriceText: String {
        "\(subscription.schedule.rawValue.capitalized) • \(subscription.price.formatted(.currency(code: "CAD")))"
    }

    var logoName: String? { subscription.logoName }

    var customization: LogoCustomization {
        subscription.logoCustomization(in: store)
    }

    func setActive(_ value: Bool) {
        isActive = value
        var updated = subscription
        updated.isActive = value
        store.update(updated)
    }

    func confirmDelete() {
        store.delete(subscription)
        coordinator.selectedSubscription = nil
    }

    func applyEdit(_ updated: Subscription) {
        store.update(updated)
        coordinator.selectedSubscription = nil
    }
}
