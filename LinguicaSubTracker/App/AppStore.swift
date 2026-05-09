import Foundation
import SwiftUI
import Combine

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

final class AppStore: ObservableObject {
    @Published var selectedDay: Date?
    @Published var selectedSubscription: Subscription?
    @Published var currentMonthIndex: Int = 0
    @Published var subscriptions: [Subscription] = []
    @Published var currentMonth: Date = Date()
    @Published var filter: SubscriptionFilter = .all
    @Published var logoCustomizations: [UUID: LogoCustomization] = [:]
    @Published var rewindRequest: Int? = nil

    init() {
        subscriptions = StorageService.load()
        logoCustomizations = StorageService.loadCustomizations()
    }

    func customization(for id: UUID) -> LogoCustomization? {
        logoCustomizations[id]
    }

    func setCustomization(_ customization: LogoCustomization) {
        logoCustomizations[customization.id] = customization
        StorageService.saveCustomizations(logoCustomizations)
    }

    func clearCustomization(id: UUID) {
        logoCustomizations.removeValue(forKey: id)
        StorageService.saveCustomizations(logoCustomizations)
    }

    var filteredSubscriptions: [Subscription] {
        subscriptions.filter { sub in
            if let list = filter.list, sub.list != list { return false }
            if let category = filter.category, sub.category != category { return false }
            if let payment = filter.paymentMethod, sub.paymentMethod != payment { return false }
            return true
        }
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
        clearCustomization(id: subscription.id)
    }
}
