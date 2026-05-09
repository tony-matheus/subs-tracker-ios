import SwiftUI

enum StatsDimension: String, CaseIterable, Identifiable {
    case categories
    case lists
    case payments

    var id: String { rawValue }

    var label: String {
        switch self {
        case .categories: return "Category"
        case .lists: return "List"
        case .payments: return "Payment"
        }
    }
}

struct DimensionMenu: View {
    @Binding var dimension: StatsDimension

    var body: some View {
        Menu {
            Picker("Dimension", selection: $dimension) {
                ForEach(StatsDimension.allCases) { dim in
                    Text(dim.label).tag(dim)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(dimension.label)
                    .typography(.titleMedium)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(Color.gray)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassEffect(.regular.interactive(), in: Capsule())
        }
        .tint(.gray)
    }
}

#Preview {
    @Previewable @State var dim: StatsDimension = .categories
    DimensionMenu(dimension: $dim)
        .padding()
        .background(.black)
}
