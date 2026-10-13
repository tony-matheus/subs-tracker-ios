import SwiftUI

struct AppearanceSelector: View {
    @Binding var selection: ThemeMode
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var doorNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ThemeMode.allCases) { mode in
                panel(for: mode)

                if mode != ThemeMode.allCases.last {
                    Rectangle()
                        .fill(Color.ruleStrong)
                        .frame(width: 1)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(4)
        .background(Color.paper, in: .rect(cornerRadius: AppRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.card)
                .strokeBorder(Color.ruleStrong, lineWidth: 1)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: selection)
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func panel(for mode: ThemeMode) -> some View {
        let isSelected = selection == mode

        return Button {
            selection = mode
        } label: {
            VStack(spacing: 0) {
                modeIcon(mode, isSelected: isSelected)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 40)

                Rectangle()
                    .fill(isSelected ? Color.ruleStrong : Color.rule)
                    .frame(height: 1)
                    .accessibilityHidden(true)

                Text(mode.label)
                    .typography(.labelMedium)
                    .foregroundStyle(isSelected ? Color.ink : Color.inkSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 28)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .background {
                if isSelected {
                    Rectangle()
                        .fill(Color.paperRaised)
                        .overlay {
                            Rectangle().strokeBorder(Color.ruleStrong, lineWidth: 1)
                        }
                        .overlay(alignment: .trailing) {
                            Rectangle().fill(Color.shu).frame(width: 4)
                        }
                        .shadow(color: Color.ink.opacity(0.1), radius: 2, y: 2)
                        .matchedGeometryEffect(id: "shojiDoor", in: doorNamespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.label) appearance")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func modeIcon(_ mode: ThemeMode, isSelected: Bool) -> some View {
        let symbol: String
        switch mode {
        case .system: symbol = "circle.lefthalf.filled"
        case .light: symbol = "sun.max.fill"
        case .dark: symbol = "moon.stars.fill"
        }

        return Image(systemName: symbol)
            .font(.system(size: 22, weight: .medium))
            .foregroundStyle(isSelected ? Color.ink : Color.inkSecondary)
            .accessibilityHidden(true)
    }
}

#Preview("Shoji · light") {
    @Previewable @State var mode: ThemeMode = .light

    AppearanceSelector(selection: $mode)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paper)
        .preferredColorScheme(.light)
}

#Preview("Shoji · dark") {
    @Previewable @State var mode: ThemeMode = .dark

    AppearanceSelector(selection: $mode)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paper)
        .preferredColorScheme(.dark)
}
