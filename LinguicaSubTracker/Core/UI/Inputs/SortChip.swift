import SwiftUI

/// Reusable sort picker chip. Shows the current sort label + chevron, opens a
/// Menu listing every `ExpenseSortType` with an arrow on the active row.
struct SortChip: View {
    let sort: ExpenseSortType
    let direction: SortDirection
    let onPick: (ExpenseSortType) -> Void

    var body: some View {
        Menu {
            ForEach(ExpenseSortType.allCases) { type in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
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
                    .typography(.bodyMedium.weight(.semibold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.1), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
