import SwiftUI

/// Stats hero — the real `SpendDial` ring chart seeded with mock category
/// spend. Interactive: drag the ring to spin between slices.
struct OnboardingStatsHero: View {
    @State private var selected: String? = "Entertainment"

    private let items: [DialItem] = [
        DialItem(id: "Entertainment", label: "Entertainment", amount: 930, color: Color(hex: "#FF3B30")),
        DialItem(id: "Productivity", label: "Productivity", amount: 250, color: Color(hex: "#34C759")),
        DialItem(id: "Lifestyle", label: "Lifestyle", amount: 166, color: Color(hex: "#FFD60A")),
    ]

    var body: some View {
        SpendDial(
            items: items,
            selectedID: $selected,
            totalLabel: "$930.00",
            percentLabel: "69%",
            hintRotationOnAppear: true
        )
        .frame(height: 260)
        .rippleCard()
    }
}

#Preview {
    OnboardingStatsHero()
        .padding(32)
        .appBackground()
}
