import Foundation
import SwiftUI
import Observation

/// Pure data layer: expenses + logo customizations + CRUD bridge to `StorageService`.
/// UI/navigation state lives on `AppCoordinator`; feature-scoped state lives on its ViewModel.
@Observable
@MainActor
final class AppStore {
    var expenses: [Expense] = []
    var logoCustomizations: [UUID: LogoCustomization] = [:]

    init() {
        expenses = StorageService.load()
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

    func add(_ expense: Expense) {
        expenses.append(expense)
        StorageService.save(expenses)
    }

    func update(_ expense: Expense) {
        guard let index = expenses.firstIndex(where: { $0.id == expense.id }) else { return }
        expenses[index] = expense
        StorageService.save(expenses)
    }

    func delete(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
        StorageService.save(expenses)
        clearCustomization(id: expense.id)
    }

    /// Wipes all expenses and per-expense logo customizations. Settings
    /// (currency, categories, payment methods, lists, budget, theme) are untouched.
    func deleteAllExpenses() {
        expenses = []
        logoCustomizations = [:]
        StorageService.save(expenses)
        StorageService.saveCustomizations(logoCustomizations)
    }
}
