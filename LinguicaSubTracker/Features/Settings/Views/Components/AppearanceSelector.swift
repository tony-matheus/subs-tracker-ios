import SwiftUI

struct AppearanceSelector: View {
    @Binding var selection: ThemeMode
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 4) {
            ForEach(ThemeMode.allCases) { mode in
                segmentContent(mode)
                    .background {
                        if selection == mode {
                            RoundedRectangle(cornerRadius: AppRadius.card)
                                .fill(Color.clear)
                                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: AppRadius.card))
                                .matchedGeometryEffect(id: "appearanceHighlight", in: ns)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard selection != mode else { return }
                        selection = mode
                    }
            }
        }
        .padding(4)
        .background(Color.paperRaised, in: .rect(cornerRadius: AppRadius.card))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.card).strokeBorder(Color.rule))
        .animation(reduceMotion ? nil : .smooth(duration: 0.25), value: selection)
        .sensoryFeedback(.selection, trigger: selection)
    }

    @ViewBuilder
    private func segmentContent(_ mode: ThemeMode) -> some View {
        let isSelected = selection == mode

        VStack(spacing: 6) {
            modeIcon(mode, isSelected: isSelected)

            Text(mode.label)
                .typography(.labelMedium)
                .foregroundStyle(isSelected ? Color.ink : Color.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func modeIcon(_ mode: ThemeMode, isSelected: Bool) -> some View {
        switch mode {
        case .system:
            Image(systemName: "circle.lefthalf.filled")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(isSelected ? Color.ink : Color.inkSecondary)




        case .light:
            Image(systemName: "sun.max.fill")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(isSelected ? Color.ink : Color.inkSecondary)





        case .dark:
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(isSelected ? Color.ink : Color.inkSecondary)



        }
    }
}

#Preview {
    @Previewable @State var mode: ThemeMode = .system

    AppearanceSelector(selection: $mode)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paperRaised)
}
