import Charts
import SwiftUI

/// Bar chart of projected spend per period (months of a year, or whole years).
/// The highlighted period renders at full opacity, others dimmed.
struct SpendTrendChart: View {
    struct Point: Identifiable, Equatable {
        let id: String
        let label: String
        let value: Double
        let color: Color
        var highlighted: Bool = false
    }

    let points: [Point]
    /// Render only the first letter of each x label (fits 12 months).
    var abbreviateLabels: Bool = false

    var body: some View {
        Chart {
            ForEach(points) { point in
                BarMark(
                    x: .value("Period", point.label),
                    y: .value("Amount", point.value)
                )
                .foregroundStyle(
                    point.color.opacity(point.highlighted ? 1 : 0.45)
                )
                .cornerRadius(4)
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        Text(abbreviateLabels ? String(label.prefix(1)) : label)
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
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: points)
    }
}

#Preview {
    let amounts: [Double] = [77, 114, 151, 188, 5, 42, 79, 116, 153, 190, 7, 44]
    let labels = Calendar.current.shortMonthSymbols
    let points = (0..<12).map { idx in
        SpendTrendChart.Point(
            id: labels[idx],
            label: labels[idx],
            value: amounts[idx] + 40,
            color: Color(hex: "#5E5CE6"),
            highlighted: idx == 6
        )
    }
    SpendTrendChart(points: points, abbreviateLabels: true)
        .frame(height: 220)
        .padding()
        .appBackground()
}
