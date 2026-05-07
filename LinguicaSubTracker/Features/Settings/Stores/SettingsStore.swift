import Foundation
import Combine
import SwiftUI

final class SettingsStore: ObservableObject {
    @Published var settings: AppSettings {
        didSet { StorageService.saveSettings(settings) }
    }

    init() {
        settings = StorageService.loadSettings()
    }

    // MARK: - Categories

    func addCategory(_ name: String, colorHex: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        settings.categories.append(AppCategory(name: name, colorHex: colorHex))
    }

    func deleteCategories(at offsets: IndexSet) {
        let deletable = offsets.filter { !settings.categories[$0].isDefault }
        settings.categories.remove(atOffsets: IndexSet(deletable))
    }

    func updateCategoryColor(id: UUID, colorHex: String) {
        guard let idx = settings.categories.firstIndex(where: { $0.id == id }) else { return }
        settings.categories[idx].colorHex = colorHex
    }

    // MARK: - Payment Methods

    func addPaymentMethod(_ name: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        settings.paymentMethods.append(PaymentMethod(name: name))
    }

    func deletePaymentMethods(at offsets: IndexSet) {
        settings.paymentMethods.remove(atOffsets: offsets)
    }

    // MARK: - Lists

    func addList(_ name: String, colorHex: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        settings.lists.append(SubscriptionList(name: name, colorHex: colorHex))
    }

    func deleteLists(at offsets: IndexSet) {
        let deletable = offsets.filter { !settings.lists[$0].isDefault }
        settings.lists.remove(atOffsets: IndexSet(deletable))
    }

    func updateListColor(id: UUID, colorHex: String) {
        guard let idx = settings.lists.firstIndex(where: { $0.id == id }) else { return }
        settings.lists[idx].colorHex = colorHex
    }
}
