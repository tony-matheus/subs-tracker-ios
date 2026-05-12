import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class PaymentMethodsViewModel {
    var newName: String = ""

    var mode: RowMode = .viewing
    var selectedIDs: Set<UUID> = []
    var editingID: UUID? = nil

    let settingsStore: SettingsStore

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    var paymentMethods: [PaymentMethod] { settingsStore.settings.paymentMethods }
    var canAdd: Bool { !newName.trimmingCharacters(in: .whitespaces).isEmpty }

    func commitAdd() {
        guard canAdd else { return }
        settingsStore.addPaymentMethod(newName)
        newName = ""
    }

    func enterSelectMode() {
        selectedIDs = []
        mode = .selecting
    }

    func enterEditMode() {
        mode = .editing
    }

    func exitMode() {
        selectedIDs = []
        mode = .viewing
    }

    func isSelectable(_ method: PaymentMethod) -> Bool {
        _ = method
        return true
    }

    func toggleSelection(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    func deleteSelected() {
        settingsStore.deletePaymentMethods(ids: selectedIDs)
    }

    func rename(id: UUID, name: String) {
        settingsStore.renamePaymentMethod(id: id, name: name)
    }

    func paymentMethod(for id: UUID) -> PaymentMethod? {
        paymentMethods.first { $0.id == id }
    }
}
