import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class CategoriesViewModel {
    var newName: String = ""
    var newColorHex: String = "#FF3B30"
    var showColorPicker = false

    var mode: RowMode = .viewing
    var selectedIDs: Set<UUID> = []
    var editingID: UUID? = nil

    let settingsStore: SettingsStore

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    var categories: [AppCategory] { settingsStore.settings.categories }
    var canAdd: Bool { !newName.trimmingCharacters(in: .whitespaces).isEmpty }
    var hasDefaultCategory: Bool { categories.contains { $0.isDefault } }

    func commitAdd() {
        guard canAdd else { return }
        settingsStore.addCategory(newName, colorHex: newColorHex)
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

    func isSelectable(_ category: AppCategory) -> Bool {
        !category.isDefault
    }

    func toggleSelection(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    func deleteSelected() {
        settingsStore.deleteCategories(ids: selectedIDs)
    }

    func rename(id: UUID, name: String) {
        settingsStore.renameCategory(id: id, name: name)
    }

    func updateColor(id: UUID, colorHex: String) {
        settingsStore.updateCategoryColor(id: id, colorHex: colorHex)
    }

    func category(for id: UUID) -> AppCategory? {
        categories.first { $0.id == id }
    }
}
