import SwiftUI

struct BudgetEditorPreviewHost: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                budgetRow(
                    label: "Budget not set",
                    budget: nil,
                    spent: 100
                )
                budgetRow(
                    label: "Low — 15 %",
                    budget: 200,
                    spent: 30
                )
                budgetRow(
                    label: "Moderate — 60 %",
                    budget: 100,
                    spent: 60
                )
                budgetRow(
                    label: "High — 85 %",
                    budget: 100,
                    spent: 85
                )

                budgetRow(
                    label: "Over — 110 %",
                    budget: 100,
                    spent: 110
                )
            }
            .padding(24)
        }
        .background(.black)
    }

    @ViewBuilder
    private func budgetRow(label: String, budget: Double?, spent: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            BudgetEditor(
                settingsStore: makeSettingsStore(budget: budget),
                store: makeStore(spent: spent)
            )
        }
    }

    private func makeSettingsStore(budget: Double?) -> SettingsStore {
        let s = SettingsStore()
        s.settings.monthlyBudget = budget
        return s
    }

    private func makeStore(spent: Double) -> AppStore {
        // Anchor to midnight on the 1st of the current month so totalForMonth
        // always counts the expense regardless of what time the preview runs.
        let startOfMonth = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: Date())
        ) ?? Date()

        let s = AppStore()
        s.expenses = [
            Expense(
                name: "Netflix",
                price: spent,
                billingCycle: .monthly,
                startDate: startOfMonth,
                category: "Entertainment",
                list: "Personal"
            ),
        ]
        return s
    }
}

#Preview {
    BudgetEditorPreviewHost()
}
