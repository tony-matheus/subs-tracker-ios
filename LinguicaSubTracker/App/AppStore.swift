import Foundation
import SwiftUI
import Combine

final class AppStore: ObservableObject {
    @Published var selectedDay: Date?
    @Published var selectedSubscription: Subscription?
    @Published var currentMonthIndex: Int = 0
    @Published var subscriptions: [Subscription] = []
    @Published var currentMonth: Date = Date()

    init() {
        subscriptions = StorageService.load()
    }

    func add(_ subscription: Subscription) {
        subscriptions.append(subscription)
        StorageService.save(subscriptions)
    }

    func update(_ subscription: Subscription) {
        guard let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) else { return }
        subscriptions[index] = subscription
        StorageService.save(subscriptions)
    }

    func delete(_ subscription: Subscription) {
        subscriptions.removeAll { $0.id == subscription.id }
        StorageService.save(subscriptions)
    }
}
