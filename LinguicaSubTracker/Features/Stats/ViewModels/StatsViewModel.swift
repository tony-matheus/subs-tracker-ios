import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class StatsViewModel {
    var year: Int = Calendar.current.component(.year, from: Date())
    var dimension: StatsDimension = .categories
    var scale: StatsScale = .yearly
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
        for expense in store.expenses {
            years.insert(calendar.component(.year, from: expense.startDate))
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
        let months = ExpenseService.monthsRemaining(in: year)
        let avg = months > 0 ? total / Double(months) : 0
        return MoneyFormatter.format(avg, settings: settingsStore.settings)
    }

    /// Per-month projected spend across the selected year (trend chart).
    var monthlySeries: [(month: Int, amount: Double)] {
        ExpenseService.monthlyForecast(store.expenses, year: year)
            .enumerated()
            .map { (month: $0.offset + 1, amount: $0.element) }
    }

    /// Full-year projected spend for every year with data (trend chart).
    var yearlySeries: [(year: Int, amount: Double)] {
        yearOptions.sorted().map { y in
            (year: y, amount: ExpenseService.monthlyForecast(store.expenses, year: y).reduce(0, +))
        }
    }

    /// Current month if the selected year is the current one; nil otherwise.
    var highlightMonth: Int? {
        let calendar = Calendar.current
        guard calendar.component(.year, from: Date()) == year else { return nil }
        return calendar.component(.month, from: Date())
    }

    /// Bar tint: budget tier when a budget is set, theme fallback otherwise.
    func trendBarColor(amount: Double) -> Color {
        if let budget = settingsStore.settings.monthlyBudget, budget > 0 {
            return BudgetColor.color(spent: amount, budget: budget)
        }
        return Self.fallbackPalette[0]
    }

    var monthlyTrendPoints: [SpendTrendChart.Point] {
        let labels = Calendar.current.shortMonthSymbols
        return monthlySeries.map { entry in
            SpendTrendChart.Point(
                id: "m\(entry.month)",
                label: labels[entry.month - 1],
                value: entry.amount,
                color: trendBarColor(amount: entry.amount),
                highlighted: entry.month == highlightMonth
            )
        }
    }

    var yearlyTrendPoints: [SpendTrendChart.Point] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return yearlySeries.map { entry in
            SpendTrendChart.Point(
                id: "y\(entry.year)",
                label: String(entry.year),
                // Tier the yearly bar by its average month against the budget.
                value: entry.amount,
                color: trendBarColor(amount: entry.amount / 12),
                highlighted: entry.year == currentYear
            )
        }
    }

    func format(_ amount: Double) -> String {
        MoneyFormatter.format(amount, settings: settingsStore.settings)
    }

    var activeCount: Int {
        store.expenses.filter { $0.isActive }.count
    }

    var activeCountLabel: String {
        "You have \(activeCount) active expense\(activeCount == 1 ? "" : "s")"
    }

    private var groupKey: (Expense) -> String? {
        switch dimension {
        case .categories: return { $0.category }
        case .lists: return { $0.list }
        case .payments: return { $0.paymentMethod }
        }
    }

    /// Month the dial shows in monthly scale: the current month when the
    /// selected year is the current one, January of that year otherwise.
    var referenceMonth: Date {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let month = year == currentYear ? calendar.component(.month, from: Date()) : 1
        return calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
    }

    /// Title above the dial reflecting scale + period.
    var breakdownTitle: String {
        switch scale {
        case .monthly:
            return referenceMonth.formatted(.dateTime.month(.wide).year())
        case .yearly:
            return "\(String(year)) forecast"
        }
    }

    private var amountsByName: [String: Double] {
        switch scale {
        case .monthly:
            return ExpenseService.totalForMonthGrouped(
                store.expenses,
                month: referenceMonth,
                key: groupKey
            )
        case .yearly:
            switch dimension {
            case .categories:
                return ExpenseService.remainingForecastByCategory(store.expenses, year: year)
            case .lists:
                return ExpenseService.remainingForecastByList(store.expenses, year: year)
            case .payments:
                return ExpenseService.remainingForecastByPaymentMethod(store.expenses, year: year)
            }
        }
    }

    /// Per-expense monthly spend lines for the selected year — top 6 by total.
    var expenseLineSeries: [ExpenseLineChart.Series] {
        let calendar = Calendar.current
        let entries: [(Expense, [Double], Double)] = store.expenses.compactMap { exp in
            let values = (1...12).map { m -> Double in
                guard let first = calendar.date(
                    from: DateComponents(year: year, month: m, day: 1)
                ) else { return 0 }
                return ExpenseService.totalForMonth([exp], month: first)
            }
            let total = values.reduce(0, +)
            return total > 0 ? (exp, values, total) : nil
        }
        return entries
            .sorted { $0.2 > $1.2 }
            .prefix(6)
            .map { exp, values, _ in
                ExpenseLineChart.Series(
                    id: exp.id.uuidString,
                    name: exp.name,
                    color: exp.logoCustomization(in: store).primaryColor,
                    values: values
                )
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
