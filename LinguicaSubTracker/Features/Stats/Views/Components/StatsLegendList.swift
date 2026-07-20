import SwiftUI

/// Ranked category legend: color dot + label + amount + thin percent bar.
/// Selection is two-way synced with the dial via `selectedID`.
struct StatsLegendList: View {
    let items: [DialItem]
    let total: Double
    @Binding var selectedID: String?
    let format: (Double) -> String

    var body: some View {
        VStack(spacing: 4) {
            ForEach(items) { item in
                legendRow(item)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: items)
    }

    private func legendRow(_ item: DialItem) -> some View {
        let fraction = total > 0 ? item.amount / total : 0
        let isSelected = selectedID == item.id

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedID = item.id
            }
        } label: {
            VStack(spacing: 6) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 10, height: 10)

                    Text(item.label)
                        .typography(.bodyMedium.weight(isSelected ? .semibold : .regular))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    Text("\(Int((fraction * 100).rounded()))%")
                        .typography(.bodySmall)
                        .foregroundStyle(.secondary)

                    Text(format(item.amount))
                        .typography(.bodyMedium.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.08))
                        Capsule()
                            .fill(item.color)
                            .frame(width: geo.size.width * fraction)
                    }
                }
                .frame(height: 4)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.primary.opacity(0.08) : Color.clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var selected: String? = "Entertainment"
    StatsLegendList(
        items: [
            DialItem(id: "Entertainment", label: "Entertainment", amount: 930, color: Color(hex: "#FF3B30")),
            DialItem(id: "Productivity", label: "Productivity", amount: 250, color: Color(hex: "#34C759")),
            DialItem(id: "Lifestyle", label: "Lifestyle", amount: 166, color: Color(hex: "#FFD60A")),
        ],
        total: 1346,
        selectedID: $selected,
        format: { "$\(Int($0))" }
    )
    .padding()
    .appBackground()
}
