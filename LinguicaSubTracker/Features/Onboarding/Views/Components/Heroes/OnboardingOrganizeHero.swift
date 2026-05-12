import SwiftUI

/// Stacked colored chips for lists, categories and payment methods.
struct OnboardingOrganizeHero: View {
    private let rows: [(icon: String, label: String, color: Color)] = [
        ("list.dash", "Lists", Color(hex: "#007AFF")),
        ("square.grid.2x2", "Categories", Color(hex: "#AF52DE")),
        ("creditcard", "Payment Methods", Color(hex: "#34C759")),
    ]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(rows, id: \.label) { row in
                HStack(spacing: 14) {
                    Image(systemName: row.icon)
                        .iconStyle(size: 18, weight: .semibold, color: row.color)
                        .frame(width: 28)
                    Text(row.label)
                        .typography(.titleMedium)
                        .foregroundStyle(.primary)
                    Spacer()
                    Circle()
                        .fill(row.color.gradient)
                        .frame(width: 12, height: 12)
                }
                .rippleCard()
                .rippleOnTap()
            }
        }
    }
}

#Preview {
    OnboardingOrganizeHero()
        .padding(32)
        .appBackground()
}
