import SwiftUI

struct StatsCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .typography(.bodyMedium)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(value)
                .typography(.headlineLarge)
                .foregroundStyle(.primary)
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
