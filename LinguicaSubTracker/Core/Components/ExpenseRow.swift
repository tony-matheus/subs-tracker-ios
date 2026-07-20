import SwiftUI

struct ExpenseRow: View {
    let expense: Expense
    var onTap: () -> Void

    @Environment(AppStore.self) private var store
    @Environment(SettingsStore.self) private var settingsStore

    private var statusColor: Color {
        expense.isActive ? .green : .gray
    }

    private var statusText: String {
        expense.isActive ? "Active" : "Inactive"
    }

    private var paymentIcon: String {
        expense.paymentMethod == nil ? "person.fill" : "creditcard.fill"
    }

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
                    Text("\(scheduleText) • \(priceText)")
                        .typography(.bodySmall)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text(statusText)
                    .typography(.labelMedium.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.18), in: Capsule())

                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 32, height: 32)
                    Image(systemName: paymentIcon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

    }
}

#Preview("ExpenseRow") {
    let store = SearchPreviewData.makeDemoStore()
    return VStack(spacing: 0) {
        ForEach(store.expenses) { expense in
            ExpenseRow(expense: expense) {
                print("Tap \(expense.name)")
            }
            Divider().padding(.leading, 76)
        }
    }
    .environment(store)
    .environment(SettingsStore())
    .background(Color.black)
}
