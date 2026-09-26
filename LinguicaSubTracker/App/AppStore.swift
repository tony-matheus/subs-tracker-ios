import Foundation
import SwiftUI
import Observation
import UIKit

/// Pure data layer: expenses + logo customizations + CRUD bridge to `StorageService`.
/// UI/navigation state lives on `AppCoordinator`; feature-scoped state lives on its ViewModel.
@Observable
@MainActor
final class AppStore {
    var expenses: [Expense] = []
    var logoCustomizations: [UUID: LogoCustomization] = [:]
    /// Told about every local write so it can queue the matching CloudKit change.
    @ObservationIgnored weak var sync: CloudSyncService?

    init() {
        expenses = StorageService.load()
        logoCustomizations = StorageService.loadCustomizations()
        // ponytail: full reindex each launch (upsert); diff it if launch cost shows up.
        ExpenseSpotlight.index(expenses)

        // Data can change outside the UI (Siri/Shortcuts intent, iCloud
        // sync). Re-read on foreground so a later in-app save doesn't
        // clobber those writes with a stale in-memory copy.
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.reloadFromDisk() }
        }
    }

    func reloadFromDisk() {
        expenses = StorageService.load()
        logoCustomizations = StorageService.loadCustomizations()
    }

    func customization(for id: UUID) -> LogoCustomization? {
        logoCustomizations[id]
    }

    func setCustomization(_ customization: LogoCustomization) {
        logoCustomizations[customization.id] = customization
        StorageService.saveCustomizations(logoCustomizations)
        sync?.expensesChanged(saved: [customization.id], deleted: [])
    }

    func clearCustomization(id: UUID) {
        logoCustomizations.removeValue(forKey: id)
        StorageService.saveCustomizations(logoCustomizations)
        // Logo rides on the expense record; a deleted expense is skipped by sync.
        sync?.expensesChanged(saved: [id], deleted: [])
    }

    func add(_ expense: Expense) {
        expenses.append(expense)
        StorageService.save(expenses)
        sync?.expensesChanged(saved: [expense.id], deleted: [])
        ExpenseSpotlight.index([expense])
    }

    func update(_ expense: Expense) {
        guard let index = expenses.firstIndex(where: { $0.id == expense.id }) else { return }
        expenses[index] = expense
        StorageService.save(expenses)
        sync?.expensesChanged(saved: [expense.id], deleted: [])
        ExpenseSpotlight.index([expense])
    }

    func delete(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
        StorageService.save(expenses)
        clearCustomization(id: expense.id)
        sync?.expensesChanged(saved: [], deleted: [expense.id])
        ExpenseSpotlight.remove([expense.id])
    }

    /// Wipes all expenses and per-expense logo customizations. Settings
    /// (currency, categories, payment methods, lists, budget, theme) are untouched.
    func deleteAllExpenses() {
        sync?.expensesChanged(saved: [], deleted: expenses.map(\.id))
        ExpenseSpotlight.remove(expenses.map(\.id))
        expenses = []
        logoCustomizations = [:]
        StorageService.save(expenses)
        StorageService.saveCustomizations(logoCustomizations)
    }

    // MARK: - iCloud

    /// Applies fetched iCloud changes without notifying sync (no echo).
    /// `logos` holds the logo for each saved expense; a saved expense missing
    /// from it has no customization.
    @discardableResult
    func applyRemote(
        saved: [Expense],
        logos: [UUID: LogoCustomization],
        deleted: [UUID]
    ) -> (inserted: Int, changed: Int) {
        let localByID = Dictionary(expenses.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let inserted = saved.count { localByID[$0.id] == nil }
        let changed = saved.count { remote in
            guard let local = localByID[remote.id] else { return false }
            return local != remote || logoCustomizations[remote.id] != logos[remote.id]
        } + deleted.count { localByID[$0] != nil }
        guard inserted + changed > 0 else { return (0, 0) }

        expenses = Self.merge(local: expenses, saved: saved, deleted: Set(deleted))
        for expense in saved { logoCustomizations[expense.id] = logos[expense.id] }
        deleted.forEach { logoCustomizations[$0] = nil }
        StorageService.save(expenses)
        StorageService.saveCustomizations(logoCustomizations)
        ExpenseSpotlight.index(saved)
        ExpenseSpotlight.remove(deleted)
        return (inserted, changed)
    }

    /// Upserts `saved` by id and drops `deleted`; local order is kept, new
    /// ids append at the end.
    static func merge(local: [Expense], saved: [Expense], deleted: Set<UUID>) -> [Expense] {
        var result = local.filter { !deleted.contains($0.id) }
        for expense in saved {
            if let index = result.firstIndex(where: { $0.id == expense.id }) {
                result[index] = expense
            } else {
                result.append(expense)
            }
        }
        return result
    }
}

// App-side conveniences over the store-free resolver in Expense+Logo.swift
// (kept here so that file also compiles into the widget extension).
extension LogoCustomization {
    static func resolved(for id: UUID, name: String, in store: AppStore) -> LogoCustomization {
        resolved(for: id, name: name, customizations: store.logoCustomizations)
    }
}

extension Expense {
    func logoCustomization(in store: AppStore) -> LogoCustomization {
        logoCustomization(customizations: store.logoCustomizations)
    }
}
