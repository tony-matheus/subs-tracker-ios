import Foundation
import SwiftUI
import Observation

/// Pure data layer: subscriptions + logo customizations + CRUD bridge to `StorageService`.
/// UI/navigation state lives on `AppCoordinator`; feature-scoped state lives on its ViewModel.
@Observable
@MainActor
final class AppStore {
    var subscriptions: [Subscription] = []
    var logoCustomizations: [UUID: LogoCustomization] = [:]

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
