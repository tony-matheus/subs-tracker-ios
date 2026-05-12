import SwiftUI

// MARK: - MenuLabelStyle

enum MenuLabelStyle {
    /// No background — label text + `chevron.down`. Matches TopBar filter menus.
    case plain
    /// Glass capsule — label text + `chevron.up.chevron.down`. Matches YearMenu / DimensionMenu.
    case glassy
}

// MARK: - MenuPicker

/// A `Menu`-wrapped picker with a styled trigger label.
/// Internally uses `AppPicker` for the selection content.
struct MenuPicker<V: Hashable>: View {
    let title: String
    @Binding var selection: V
    let options: [(value: V, label: String)]
    var style: MenuLabelStyle = .plain

    private var selectedLabel: String {
        options.first(where: { $0.value == selection })?.label ?? title
    }

    var body: some View {
        Menu {
            AppPicker(title: title, selection: $selection, options: options)
        } label: {
            menuLabel
        }
        .tint(style == .glassy ? .gray : nil)
    }

    @ViewBuilder
    private var menuLabel: some View {
        switch style {
        case .plain:
            HStack(spacing: 4) {
                Text(selectedLabel)
                    .typography(.titleSmall)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.gray)

        case .glassy:
            HStack(spacing: 4) {
                Text(selectedLabel)
                    .typography(.titleMedium)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.gray)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassEffect(.regular.interactive(), in: Capsule())
        }
    }
}

// MARK: - Previews

#Preview("MenuPicker — plain") {
    @Previewable @State var selection: String = "All Lists"

    let options: [(value: String, label: String)] = [
        (value: "All Lists", label: "All Lists"),
        (value: "Personal", label: "Personal"),
        (value: "Work", label: "Work"),
    ]

    MenuPicker(title: "Lists", selection: $selection, options: options, style: .plain)
        .padding()
        .background(.black)
}

#Preview("MenuPicker — glassy") {
    @Previewable @State var year: Int = 2026

    let options = [2026, 2025, 2024].map { (value: $0, label: String($0)) }

    MenuPicker(title: "Year", selection: $year, options: options, style: .glassy)
        .padding()
        .background(.black)
}

#Preview("Both MenuPicker styles") {
    @Previewable @State var plain: String = "Personal"
    @Previewable @State var glassy: Int = 2026

    let stringOptions = [
        (value: "Personal", label: "Personal"),
        (value: "Work", label: "Work"),
        (value: "Family", label: "Family"),
    ]
    let yearOptions = [2026, 2025, 2024].map { (value: $0, label: String($0)) }

    VStack(spacing: 24) {
        MenuPicker(title: "List", selection: $plain, options: stringOptions, style: .plain)
        MenuPicker(title: "Year", selection: $glassy, options: yearOptions, style: .glassy)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.black)
}
