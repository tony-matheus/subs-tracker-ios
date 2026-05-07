import SwiftUI

struct BudgetEditor: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var store: AppStore

    @State private var showKeypad = false
    @State private var budgetAmount: Double = 0
    @State private var currencyCode: String = "CAD"

    private var settings: AppSettings { settingsStore.settings }

    private var monthlyTotal: Double {
        SubscriptionService.totalForMonth(store.subscriptions, month: store.currentMonth)
    }

    private var ratio: Double {
        guard let budget = settings.monthlyBudget, budget > 0 else { return 0 }
        return min(monthlyTotal / budget, 1)
    }

    private var progressColor: Color {
        BudgetColor.color(spent: monthlyTotal, budget: settings.monthlyBudget)
    }

    private var formattedBudget: String {
        guard let budget = settings.monthlyBudget else { return "Not set" }
        return MoneyFormatter.format(budget, settings: settings)
    }

    private var formattedTotal: String {
        MoneyFormatter.format(monthlyTotal, settings: settings)
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Monthly Budget")
                        .typography(.bodyLarge)
                        .foregroundStyle(.secondary)

                    Button {
                        budgetAmount = settings.monthlyBudget ?? 0
                        currencyCode = settings.currencyCode
                        showKeypad = true
                    } label: {
                        Text(formattedBudget)
                            .typography(.headlineSmall)
                            .foregroundStyle(settings.monthlyBudget == nil ? .secondary : .primary)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: formattedBudget)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if settings.monthlyBudget != nil {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            settingsStore.settings.monthlyBudget = nil
                        }
                    } label: {
                        Text("Clear")
                            .typography(.labelMedium)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
            }

            if settings.monthlyBudget != nil {
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)

                            Capsule()
                                .fill(progressColor)
                                .frame(width: geo.size.width * ratio, height: 6)
                                .animation(.spring(response: 0.5, dampingFraction: 0.75), value: ratio)
                        }
                    }
                    .frame(height: 6)

                    HStack {
                        Text(formattedTotal)
                            .typography(.bodySmall)
                            .foregroundStyle(progressColor)
                            .animation(.easeInOut(duration: 0.4), value: progressColor)

                        Spacer()

                        if let budget = settings.monthlyBudget {
                            Text(MoneyFormatter.format(budget, settings: settings))
                                .typography(.bodySmall)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showKeypad) {
            NumKeyPadSheet(amount: $budgetAmount, currencyCode: $currencyCode) {
                showKeypad = false
                if budgetAmount > 0 {
                    settingsStore.settings.monthlyBudget = budgetAmount
                }
            }
            .presentationDetents([.height(560)])
            .presentationDragIndicator(.visible)
        }
    }
}
