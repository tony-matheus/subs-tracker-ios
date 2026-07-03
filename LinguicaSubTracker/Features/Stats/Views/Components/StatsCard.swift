import SwiftUI

struct StatsCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .typography(.titleSmall)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(value)
                .typography(.headlineLarge.weight(.bold))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    HStack {
        StatsCard(title: "Yearly\nForecast", value: "$1346")
        StatsCard(title: "Average\nMonthly Cost", value: "$112")
    }
    .padding()
}
