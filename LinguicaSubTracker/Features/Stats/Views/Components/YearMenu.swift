import SwiftUI

struct YearMenu: View {
    @Binding var year: Int
    let options: [Int]

    var body: some View {
        MenuPicker(
            title: "Year",
            selection: $year,
            options: options.map { (value: $0, label: String($0)) },
            style: .glassy
        )
    }
}

#Preview {
    @Previewable @State var year = 2026
    YearMenu(year: $year, options: [2026, 2025, 2024])
        .padding()
        .background(.black)
}
