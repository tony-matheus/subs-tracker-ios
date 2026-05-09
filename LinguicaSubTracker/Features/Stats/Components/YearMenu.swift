import SwiftUI

struct YearMenu: View {
    @Binding var year: Int
    let options: [Int]

    var body: some View {
        Menu {
            Picker("Year", selection: $year) {
                ForEach(options, id: \.self) { y in
                    Text(String(y)).tag(y)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(String(year))
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
    @Previewable @State var year = 2026
    YearMenu(year: $year, options: [2026, 2025, 2024])
        .padding()
        .background(.black)
}
