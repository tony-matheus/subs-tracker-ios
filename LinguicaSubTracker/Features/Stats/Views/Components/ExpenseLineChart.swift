import Charts
import SwiftUI

/// One line per expense across the 12 months of a year, tinted with the
/// expense's brand color. Legend chips underneath.
struct ExpenseLineChart: View {
    struct Series: Identifiable, Equatable {
        let id: String
        let name: String
        let color: Color
        /// Amount per month, index 0 = January. Always 12 entries.
        let values: [Double]
    }

    let series: [Series]

    private static let monthLabels = Calendar.current.shortMonthSymbols

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            chart
            legend
        }
    }

    private var chart: some View {
        Chart {
            ForEach(series) { line in
                ForEach(Array(line.values.enumerated()), id: \.offset) { idx, value in
                    LineMark(
                        x: .value("Month", Self.monthLabels[idx]),
                        y: .value("Amount", value),
                        series: .value("Expense", line.name)
                    )
                    .foregroundStyle(line.color)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        Text(String(label.prefix(1)))
                            .typography(.labelMedium)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine().foregroundStyle(Color.primary.opacity(0.08))
                AxisValueLabel()
                    .foregroundStyle(.secondary)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: series)
    }

    private var legend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(series) { line in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(line.color)
                            .frame(width: 8, height: 8)
                        Text(line.name)
                            .typography(.bodySmall)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

#Preview {
    ExpenseLineChart(
        series: [
            .init(id: "1", name: "Netflix", color: Color(hex: "#E50914"),
                  values: [17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17]),
            .init(id: "2", name: "Spotify", color: Color(hex: "#1DB954"),
                  values: [0, 0, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11]),
            .init(id: "3", name: "iCloud", color: Color(hex: "#64D2FF"),
                  values: [4, 4, 4, 4, 4, 4, 13, 13, 13, 13, 13, 13]),
        ]
    )
    .frame(height: 260)
    .padding()
    .appBackground()
}
