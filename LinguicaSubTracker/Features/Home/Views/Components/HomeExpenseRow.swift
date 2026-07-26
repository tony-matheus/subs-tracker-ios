import SwiftUI

/// List-row variant for `HomeListView`: trades the status badge and payment
/// icon for a bigger, trailing price — the list already implies "active".
struct HomeExpenseRow: View {
    let expense: Expense
    var onTap: () -> Void

    @Environment(AppStore.self) private var store
    @Environment(SettingsStore.self) private var settingsStore

    private var priceText: String {
        expense.price.formatted(.currency(code: settingsStore.settings.currencyCode))
    }

    private var scheduleText: String {
        "\(expense.type.displayName) · \(expense.billingCycle.displayName)"
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                LogoCircle(
                    size: 44,
                    customization: expense.logoCustomization(in: store),
                    logoName: expense.logoName,
                    name: expense.name
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(expense.name)
                        .typography(.titleMedium.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(scheduleText)
                        .typography(.bodySmall)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text(priceText)
                    .typography(.titleLarge.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("HomeExpenseRow") {
    let store = HomePreviewData.makeStore()
    return VStack(spacing: 0) {
        ForEach(store.expenses) { expense in
            HomeExpenseRow(expense: expense) {
                print("Tap \(expense.name)")
            }
            Divider().padding(.leading, 76)
        }
    }
    .environment(store)
    .environment(SettingsStore())
    .background(Color.black)
}
