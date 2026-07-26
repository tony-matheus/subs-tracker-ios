import SwiftUI

/// Renders labelled CoinProgress scenarios for quick visual verification.
/// Each scenario is self-contained and does not go through HomePreviewData.
struct CoinProgressPreviewHost: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                scenario(
                    title: "Scenario 1 — 44/33/13/10% (10 coins, no leftover)",
                    spends: [
                        spend("Entertainment", amount: 44, hex: "#FF3B30"),
                        spend("Lifestyle",      amount: 33, hex: "#FF9500"),
                        spend("Utilities",      amount: 13, hex: "#34C759"),
                        spend("Productivity",   amount: 10, hex: "#007AFF"),
                    ],
                    budget: nil
                )

                scenario(
                    title: "Scenario 2 — 20/33/13/10% + 24% left (budget set)",
                    spends: [
                        spend("Entertainment", amount: 20, hex: "#FF3B30"),
                        spend("Lifestyle",      amount: 33, hex: "#FF9500"),
                        spend("Utilities",      amount: 13, hex: "#34C759"),
                        spend("Productivity",   amount: 10, hex: "#007AFF"),
                    ],
                    budget: 100
                )

                scenario(
                    title: "Scenario 3 — 10/20% + 70% left (budget set)",
                    spends: [
                        spend("Entertainment", amount: 10, hex: "#FF3B30"),
                        spend("Lifestyle",      amount: 20, hex: "#FF9500"),
                    ],
                    budget: 100
                )

                scenario(
                    title: "Over budget — 120 spent vs 100 budget",
                    spends: [
                        spend("Entertainment", amount: 60, hex: "#FF3B30"),
                        spend("Lifestyle",      amount: 60, hex: "#FF9500"),
                    ],
                    budget: 100
                )

                scenario(
                    title: "No budget — relative share only",
                    spends: [
                        spend("Entertainment", amount: 50, hex: "#FF3B30"),
                        spend("Lifestyle",      amount: 30, hex: "#FF9500"),
                        spend("Utilities",      amount: 20, hex: "#34C759"),
                    ],
                    budget: nil
                )

                scenario(
                    title: "12 categories — expanded rule (1 + tens digit each)",
                    spends: (1...12).map { i in
                        spend("Cat \(i)", amount: Double(i), hex: categoryHex(i))
                    },
                    budget: nil
                )

                scenario(
                    title: "Zero spend — 10 placeholder coins",
                    spends: [],
                    budget: 200
                )
            }
            .padding()
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }

    // MARK: - Helpers

    private func scenario(
        title: String,
        spends: [TotalViewModel.CategorySpend],
        budget: Double?
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            CoinProgress(spends: spends, budget: budget)
        }
    }

    private func spend(_ name: String, amount: Double, hex: String) -> TotalViewModel.CategorySpend {
        TotalViewModel.CategorySpend(name: name, amount: amount, color: Color(hex: hex))
    }

    private func categoryHex(_ index: Int) -> String {
        let hues = ["#FF3B30", "#FF9500", "#FFCC00", "#34C759",
                    "#00C7BE", "#30B0C7", "#007AFF", "#5856D6",
                    "#AF52DE", "#FF2D55", "#A2845E", "#8E8E93"]
        return hues[(index - 1) % hues.count]
    }
}

#Preview {
    CoinProgressPreviewHost()
}
