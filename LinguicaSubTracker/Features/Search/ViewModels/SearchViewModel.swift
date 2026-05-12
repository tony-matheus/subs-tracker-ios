import Foundation
import Observation
import SwiftUI

/// Single VM merging the previous SearchViewModel + AllSubscriptionsViewModel.
/// Owns search text, sort + direction, selection mode, bulk delete state, and
/// the add-sheet flag.
///
/// `displayedSubscriptions` always returns the sorted full list, filtered by
/// `searchText` when a query is present.
@Observable
@MainActor
final class SearchViewModel {
    // MARK: - State
    var searchText: String = ""
    var sort: SubscriptionSortType = .price
    var direction: SortDirection = .descending

    var isSelectionMode: Bool = false
    var selectedIDs: Set<UUID> = []
    var showBulkDeleteAlert: Bool = false
    var showAddSheet: Bool = false

    let store: AppStore
    let coordinator: AppCoordinator

    init(store: AppStore, coordinator: AppCoordinator) {
        self.store = store
        self.coordinator = coordinator
    }

    // MARK: - Derived
    var hasQuery: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var storeIsEmpty: Bool { store.subscriptions.isEmpty }

    var selectionCount: Int { selectedIDs.count }
    var hasSelection: Bool { !selectedIDs.isEmpty }

    /// Sorted then optionally filtered list — what the view renders.
    var displayedSubscriptions: [Subscription] {
        let base = sortedSubscriptions
        guard hasQuery else { return base }
        let q = searchText.trimmingCharacters(in: .whitespaces)
        return base.compactMap { sub -> (Subscription, Int)? in
            if let score = sub.name.smartMatchScore(for: q) {
                return (sub, score)
            }
            if matchesKeyword(sub, query: q) {
                return (sub, 5)
            }
            return nil
        }
        .sorted { $0.1 < $1.1 }
        .map(\.0)
    }

    // MARK: - Selection
    func enterSelectionMode() {
        isSelectionMode = true
        selectedIDs.removeAll()
    }

    func exitSelectionMode() {
        isSelectionMode = false
        selectedIDs.removeAll()
    }

    func toggleSelection(_ subscription: Subscription) {
        if selectedIDs.contains(subscription.id) {
            selectedIDs.remove(subscription.id)
        } else {
            selectedIDs.insert(subscription.id)
        }
    }

    func isSelected(_ subscription: Subscription) -> Bool {
        selectedIDs.contains(subscription.id)
    }

    func selectAll() {
        selectedIDs = Set(displayedSubscriptions.map { $0.id })
    }

    func deleteSelected() {
        let toDelete = store.subscriptions.filter { selectedIDs.contains($0.id) }
        toDelete.forEach { store.delete($0) }
        exitSelectionMode()
    }

    // MARK: - Detail push (coordinator-mediated)
    var selectedSubscription: Subscription? { coordinator.selectedSubscription }

    func selectSubscription(_ subscription: Subscription) {
        coordinator.selectedSubscription = subscription
    }

    func selectedSubscriptionBinding() -> Binding<Bool> {
        Binding(
            get: { self.coordinator.selectedSubscription != nil },
            set: { if !$0 { self.coordinator.selectedSubscription = nil } }
        )
    }

    // MARK: - Sort
    func handleSortPick(_ type: SubscriptionSortType) {
        if sort == type {
            direction.toggle()
        } else {
            sort = type
            direction = type.defaultDirection
        }
    }

    // MARK: - Delete (single)
    func delete(_ subscription: Subscription) {
        store.delete(subscription)
    }

    // MARK: - Private
    private var sortedSubscriptions: [Subscription] {
        let subs = store.subscriptions
        let asc = direction == .ascending
        switch sort {
        case .status:
            return subs.sorted { lhs, rhs in
                if lhs.isActive == rhs.isActive {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return asc ? (!lhs.isActive && rhs.isActive) : (lhs.isActive && !rhs.isActive)
            }
        case .name:
            return subs.sorted {
                let result = $0.name.localizedCaseInsensitiveCompare($1.name)
                return asc ? result == .orderedAscending : result == .orderedDescending
            }
        case .price:
            return subs.sorted { asc ? $0.price < $1.price : $0.price > $1.price }
        case .renewal:
            return subs.sorted { lhs, rhs in
                let l = SubscriptionService.nextPayment(for: lhs) ?? .distantFuture
                let r = SubscriptionService.nextPayment(for: rhs) ?? .distantFuture
                return asc ? l < r : l > r
            }
        case .paymentMethod:
            return subs.sorted {
                let l = $0.paymentMethod ?? ""
                let r = $1.paymentMethod ?? ""
                let result = l.localizedCaseInsensitiveCompare(r)
                return asc ? result == .orderedAscending : result == .orderedDescending
            }
        }
    }

    private func matchesKeyword(_ sub: Subscription, query: String) -> Bool {
        let q = query.lowercased()
        let schedule = sub.schedule == .monthly ? "monthly" : "yearly"
        if schedule.hasPrefix(q)                                          { return true }
        let status = sub.isActive ? "active" : "inactive"
        if status.hasPrefix(q)                                            { return true }
        if let pm = sub.paymentMethod, pm.isSmartMatch(for: query)        { return true }
        if sub.category.isSmartMatch(for: query)                          { return true }
        return false
    }
}
