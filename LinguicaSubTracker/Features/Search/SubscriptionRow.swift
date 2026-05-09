import SwiftUI

struct SubscriptionRow: View {
    let subscription: Subscription
    var onTap: () -> Void

    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var settingsStore: SettingsStore

    private var statusColor: Color {
        subscription.isActive ? .green : .gray
    }

    private var statusText: String {
        subscription.isActive ? "Active" : "Inactive"
    }

    private var paymentIcon: String {
        subscription.paymentMethod == nil ? "person.fill" : "creditcard.fill"
    }

    private var priceText: String {
        subscription.price.formatted(.currency(code: settingsStore.settings.currencyCode))
    }

    private var scheduleText: String {
        subscription.schedule == .monthly ? "Monthly" : "Yearly"
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                SubscriptionLogoCircle(
                    size: 44,
                    color: Color(hex: subscription.colorHex),
                    logoName: SubscriptionTemplate.logoName(for: subscription.name),
                    name: subscription.name,
                    customization: store.customization(for: subscription.id)
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(subscription.name)
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
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 32, height: 32)
                    Image(systemName: paymentIcon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
