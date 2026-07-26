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

    var calendarStyle: CalendarStyle {
        get { settings.calendarStyle ?? .rounded }
        set { settings.calendarStyle = newValue }
    }


    // MARK: - Budget

    /// Per-category slices of the monthly budget, keyed by category name.
    var categoryBudgets: [String: Double] {
        get { settings.categoryBudgets ?? [:] }
        set { settings.categoryBudgets = newValue.isEmpty ? nil : newValue }
    }

    /// A strict budget never stretches past the amount the user typed.
    var isStrictBudget: Bool {
        get { settings.strictBudget ?? false }
        set { settings.strictBudget = newValue }
    }

    /// Sum of every per-category slice.
    var allocatedBudget: Double { categoryBudgets.values.reduce(0, +) }

    /// The ceiling every budget read should use: a flexible budget grows to
    /// cover its slices once they outgrow the general amount, a strict one
    /// stays put (and the editor warns instead).
    var effectiveBudget: Double? {
        guard let budget = settings.monthlyBudget else { return nil }
        return isStrictBudget ? budget : max(budget, allocatedBudget)
    }

    /// `nil`/non-positive amount removes the slice.
    func setCategoryBudget(_ name: String, amount: Double?) {
        var budgets = categoryBudgets
        if let amount, amount > 0 {
            budgets[name] = amount
        } else {
            budgets[name] = nil
        }
        categoryBudgets = budgets
    }

    /// Clears the per-category split, keeping the general budget.
    func resetCategoryBudgets() {
        settings.categoryBudgets = nil
    }

    /// Removes the budget entirely — amount, split and strictness.
    func deleteBudget() {
        settings.monthlyBudget = nil
        settings.categoryBudgets = nil
        settings.strictBudget = nil
    }


    func addCategory(_ name: String, colorHex: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        settings.categories.append(AppCategory(name: name, colorHex: colorHex))
    }

    func deleteCategories(ids: Set<UUID>) {
        let dropped = settings.categories
            .filter { ids.contains($0.id) && !$0.isDefault }
            .map(\.name)
        settings.categories.removeAll { ids.contains($0.id) && !$0.isDefault }
        // Budget slices are keyed by name — drop the orphans with them.
        var budgets = categoryBudgets
        dropped.forEach { budgets[$0] = nil }
        categoryBudgets = budgets
    }

    func updateCategoryColor(id: UUID, colorHex: String) {
        guard let idx = settings.categories.firstIndex(where: { $0.id == id }) else { return }
        settings.categories[idx].colorHex = colorHex
    }

    func renameCategory(id: UUID, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard let idx = settings.categories.firstIndex(where: { $0.id == id }) else { return }
        let old = settings.categories[idx].name
        settings.categories[idx].name = trimmed
        // Carry the budget slice over to the new key.
        if let slice = categoryBudgets[old], old != trimmed {
            var budgets = categoryBudgets
            budgets[old] = nil
            budgets[trimmed] = slice
            categoryBudgets = budgets
        }
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
        settings.lists.append(ExpenseList(name: name, colorHex: colorHex))
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

    /// Resets currency, categories, payment methods, lists, budget and theme
    /// back to their defaults.
    func resetToDefaults() {
        settings = .default
    }
}
