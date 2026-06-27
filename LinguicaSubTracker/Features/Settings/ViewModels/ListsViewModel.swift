import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class ListsViewModel {
    var newName: String = ""
    var newColorHex: String = "#007AFF"
    var showColorPicker = false

    var mode: RowMode = .viewing
    var selectedIDs: Set<UUID> = []
    var editingID: UUID? = nil

    let settingsStore: SettingsStore

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    var lists: [ExpenseList] { settingsStore.settings.lists }
    var canAdd: Bool { !newName.trimmingCharacters(in: .whitespaces).isEmpty }

    func commitAdd() {
        guard canAdd else { return }
        settingsStore.addList(newName, colorHex: newColorHex)
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

    func isSelectable(_ list: ExpenseList) -> Bool {
        !list.isDefault
    }

    func toggleSelection(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    func deleteSelected() {
        settingsStore.deleteLists(ids: selectedIDs)
    }

    func rename(id: UUID, name: String) {
        settingsStore.renameList(id: id, name: name)
    }

    func updateColor(id: UUID, colorHex: String) {
        settingsStore.updateListColor(id: id, colorHex: colorHex)
    }

    func list(for id: UUID) -> ExpenseList? {
        lists.first { $0.id == id }
    }
}
