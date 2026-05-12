import Foundation
import SwiftUI
import Observation

@Observable
@MainActor
final class SettingsStore {
    var settings: AppSettings {
        didSet { StorageService.saveSettings(settings) }
    }

    init() {
        settings = StorageService.loadSettings()
    }

    var themeMode: ThemeMode {
        get { settings.themeMode ?? .system }
        set { settings.themeMode = newValue }
    }


    func addCategory(_ name: String, colorHex: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        settings.categories.append(AppCategory(name: name, colorHex: colorHex))
    }

    func deleteCategories(ids: Set<UUID>) {
        settings.categories.removeAll { ids.contains($0.id) && !$0.isDefault }
    }

    func updateCategoryColor(id: UUID, colorHex: String) {
        guard let idx = settings.categories.firstIndex(where: { $0.id == id }) else { return }
        settings.categories[idx].colorHex = colorHex
    }

    func renameCategory(id: UUID, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard let idx = settings.categories.firstIndex(where: { $0.id == id }) else { return }
        settings.categories[idx].name = trimmed
    }


    func addPaymentMethod(_ name: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        settings.paymentMethods.append(PaymentMethod(name: name))
    }

    func deletePaymentMethods(ids: Set<UUID>) {
        settings.paymentMethods.removeAll { ids.contains($0.id) }
    }

    func renamePaymentMethod(id: UUID, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard let idx = settings.paymentMethods.firstIndex(where: { $0.id == id }) else { return }
        settings.paymentMethods[idx].name = trimmed
    }


    func addList(_ name: String, colorHex: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        settings.lists.append(SubscriptionList(name: name, colorHex: colorHex))
    }

    func deleteLists(ids: Set<UUID>) {
        settings.lists.removeAll { ids.contains($0.id) && !$0.isDefault }
    }

    func updateListColor(id: UUID, colorHex: String) {
        guard let idx = settings.lists.firstIndex(where: { $0.id == id }) else { return }
        settings.lists[idx].colorHex = colorHex
    }

    func renameList(id: UUID, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard let idx = settings.lists.firstIndex(where: { $0.id == id }) else { return }
        settings.lists[idx].name = trimmed
    }
}
