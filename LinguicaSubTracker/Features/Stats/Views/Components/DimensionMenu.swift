import SwiftUI

struct DimensionMenu: View {
    @Binding var dimension: StatsDimension

    var body: some View {
        MenuPicker(
            title: "Dimension",
            selection: $dimension,
            options: StatsDimension.allCases.map { (value: $0, label: $0.label) },
            style: .glassy
        )
    }
}

#Preview {
    @Previewable @State var dim: StatsDimension = .categories
    DimensionMenu(dimension: $dim)
        .padding()
        .background(.black)
}
