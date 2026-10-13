import SwiftUI

/// Reusable sort picker chip. Shows the current sort label + chevron, opens a
/// Menu listing every `ExpenseSortType` with an arrow on the active row.
struct SortChip: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let sort: ExpenseSortType
    let direction: SortDirection
    let onPick: (ExpenseSortType) -> Void

    var body: some View {
        Menu {
            ForEach(ExpenseSortType.allCases) { type in
                Button {
                    withAnimation(reduceMotion ? nil : .smooth(duration: 0.25)) {
                        onPick(type)
                    }
                } label: {
                    HStack {
                        Text(type.label)
                        if type == sort {
                            Spacer()
                            Image(systemName: direction.arrow)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(sort.label)
                    .typography(.bodyMedium)
                    .foregroundStyle(Color.ink)
                    .contentTransition(.numericText())
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.inkSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: AppRadius.card))
        }
        .buttonStyle(.plain)
    }
}
