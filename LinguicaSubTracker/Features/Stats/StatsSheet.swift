import SwiftUI

struct StatsSheet: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settingsStore: SettingsStore

    @State private var year: Int = Calendar.current.component(
        .year,
        from: Date()
    )
    @State private var dimension: StatsDimension = .categories
    @State private var selectedID: String?

    private static let fallbackPalette: [Color] = [
        "#5E5CE6", "#FF9F0A", "#30D158", "#FF375F",
        "#64D2FF", "#BF5AF2", "#FFD60A", "#FF6482",
    ].map { Color(hex: $0) }

    private var yearOptions: [Int] {
        let calendar = Calendar.current
        let current = calendar.component(.year, from: Date())
        var years = Set<Int>([current])
        for sub in store.subscriptions {
            years.insert(calendar.component(.year, from: sub.startDate))
        }
        return Array(years).sorted(by: >)
    }

    private var amountsByName: [String: Double] {
        switch dimension {
        case .categories:
            return SubscriptionService.remainingForecastByCategory(
                store.subscriptions,
                year: year
            )
        case .lists:
            return SubscriptionService.remainingForecastByList(
                store.subscriptions,
                year: year
            )
        case .payments:
            return SubscriptionService.remainingForecastByPaymentMethod(
                store.subscriptions,
                year: year
            )
        }
    }

    private var items: [DialItem] {
        let entries =
            amountsByName
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

    private func color(for name: String, fallbackIndex: Int) -> Color {
        let hex: String?
        switch dimension {
        case .categories:
            hex =
                settingsStore.settings.categories.first { $0.name == name }?
                .colorHex
        case .lists:
            hex =
                settingsStore.settings.lists.first { $0.name == name }?.colorHex
        case .payments:
            hex = nil
        }
        if let hex { return Color(hex: hex) }
        return Self.fallbackPalette[fallbackIndex % Self.fallbackPalette.count]
    }

    private var total: Double {
        items.reduce(0) { $0 + $1.amount }
    }

    private var selectedItem: DialItem? {
        guard let id = selectedID else { return items.first }
        return items.first { $0.id == id } ?? items.first
    }

    private var selectedAmountLabel: String {
        guard let item = selectedItem else { return "" }
        return MoneyFormatter.format(
            item.amount,
            settings: settingsStore.settings
        )
    }

    private var selectedPercentLabel: String {
        guard let item = selectedItem, total > 0 else { return "0%" }
        let pct = Int((item.amount / total * 100).rounded())
        return "\(pct)%"
    }

    private var forecastLabel: String {
        MoneyFormatter.format(total, settings: settingsStore.settings)
    }

    private var averageMonthlyLabel: String {
        let months = SubscriptionService.monthsRemaining(in: year)
        let avg = months > 0 ? total / Double(months) : 0
        return MoneyFormatter.format(avg, settings: settingsStore.settings)
    }

    private var activeCount: Int {
        store.subscriptions.filter { $0.isActive }.count
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                YearMenu(year: $year, options: yearOptions)
                Spacer()
                DimensionMenu(dimension: $dimension)
            }

            Text(
                "You have \(activeCount) active subscription\(activeCount == 1 ? "" : "s")"
            )
            .typography(.bodyMedium)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
            SpendDial(
                items: items,
                selectedID: $selectedID,
                totalLabel: selectedAmountLabel,
                percentLabel: selectedPercentLabel
            )
            .frame(height: 250)
            Spacer()
            
            HStack(spacing: 12) {
                StatsCard(title: "Yearly\nForecast", value: forecastLabel)
                StatsCard(
                    title: "Average\nMonthly Cost",
                    value: averageMonthlyLabel
                )
            }
        }
        .padding(20)
    }
}

#Preview {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            StatsSheet()
                .environmentObject(
                    {
                        let s = AppStore()
                        s.subscriptions = [
                            Subscription(
                                name: "Netflix",
                                price: 15.99,
                                colorHex: "#E50914",
                                schedule: .monthly,
                                startDate: Date(),
                                category: "Entertainment",
                                list: "Personal"
                            ),
                            Subscription(
                                name: "Spotify",
                                price: 10.99,
                                colorHex: "#1DB954",
                                schedule: .monthly,
                                startDate: Date(),
                                category: "Entertainment",
                                list: "Personal"
                            ),
                            Subscription(
                                name: "iCloud",
                                price: 2.99,
                                colorHex: "#007AFF",
                                schedule: .monthly,
                                startDate: Date(),
                                category: "Utilities",
                                list: "Personal"
                            ),
                        ]
                        return s
                    }()
                )
                .environmentObject(SettingsStore())
        }
}
