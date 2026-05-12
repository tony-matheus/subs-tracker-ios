import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class StatsViewModel {
    var year: Int = Calendar.current.component(.year, from: Date())
    var dimension: StatsDimension = .categories
    var selectedID: String?

    private let store: AppStore
    private let settingsStore: SettingsStore

    init(store: AppStore, settingsStore: SettingsStore) {
        self.store = store
        self.settingsStore = settingsStore
    }

    private static let fallbackPalette: [Color] = [
        "#5E5CE6", "#FF9F0A", "#30D158", "#FF375F",
        "#64D2FF", "#BF5AF2", "#FFD60A", "#FF6482",
    ].map { Color(hex: $0) }

    var yearOptions: [Int] {
        let calendar = Calendar.current
        let current = calendar.component(.year, from: Date())
        var years = Set<Int>([current])
        for sub in store.subscriptions {
            years.insert(calendar.component(.year, from: sub.startDate))
        }
        return Array(years).sorted(by: >)
    }

    var items: [DialItem] {
        let amounts = amountsByName
        let entries = amounts
            .filter { $0.value > 0 }
            .sorted { $0.value > $1.value }

        return entries.enumerated().map { idx, entry in
            DialItem(
                id: entry.key,
                label: entry.key,
                amount: entry.value,
                color: color(for: entry.key, fallbackIndex: idx)
            )
        }
    }

    var total: Double {
        items.reduce(0) { $0 + $1.amount }
    }

    var selectedItem: DialItem? {
        guard let id = selectedID else { return items.first }
        return items.first { $0.id == id } ?? items.first
    }

    var selectedAmountLabel: String {
        guard let item = selectedItem else { return "" }
        return MoneyFormatter.format(item.amount, settings: settingsStore.settings)
    }

    var selectedPercentLabel: String {
        guard let item = selectedItem, total > 0 else { return "0%" }
        let pct = Int((item.amount / total * 100).rounded())
        return "\(pct)%"
    }

    var forecastLabel: String {
        MoneyFormatter.format(total, settings: settingsStore.settings)
    }

    var averageMonthlyLabel: String {
        let months = SubscriptionService.monthsRemaining(in: year)
        let avg = months > 0 ? total / Double(months) : 0
        return MoneyFormatter.format(avg, settings: settingsStore.settings)
    }

    var activeCount: Int {
        store.subscriptions.filter { $0.isActive }.count
    }

    var activeCountLabel: String {
        "You have \(activeCount) active subscription\(activeCount == 1 ? "" : "s")"
    }

    private var amountsByName: [String: Double] {
        switch dimension {
        case .categories:
            return SubscriptionService.remainingForecastByCategory(store.subscriptions, year: year)
        case .lists:
            return SubscriptionService.remainingForecastByList(store.subscriptions, year: year)
        case .payments:
            return SubscriptionService.remainingForecastByPaymentMethod(store.subscriptions, year: year)
        }
    }

    private func color(for name: String, fallbackIndex: Int) -> Color {
        let hex: String?
        switch dimension {
        case .categories:
            hex = settingsStore.settings.categories.first { $0.name == name }?.colorHex
        case .lists:
            hex = settingsStore.settings.lists.first { $0.name == name }?.colorHex
        case .payments:
            hex = nil
        }
        if let hex { return Color(hex: hex) }
        return Self.fallbackPalette[fallbackIndex % Self.fallbackPalette.count]
    }
}
