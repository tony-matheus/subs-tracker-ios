import SwiftUI

struct AppearanceSelector: View {
    @Binding var selection: ThemeMode
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 4) {
            ForEach(ThemeMode.allCases) { mode in
                segmentContent(mode)
                    .background {
                        if selection == mode {
                            Capsule()
                                .fill(Color.clear)
                                .glassEffect(.regular.interactive(), in: Capsule())
                                .matchedGeometryEffect(id: "appearanceHighlight", in: ns)
                        }
                    }
                    .contentShape(Capsule())
                    .onTapGesture {
                        guard selection != mode else { return }
                        selection = mode
                    }
            }
        }
        .padding(4)
        .background(.ultraThinMaterial.opacity(0.5), in: Capsule())
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: selection)
        .sensoryFeedback(.selection, trigger: selection)
    }

    @ViewBuilder
    private func segmentContent(_ mode: ThemeMode) -> some View {
        let isSelected = selection == mode

        VStack(spacing: 6) {
            modeIcon(mode, isSelected: isSelected)

            Text(mode.label)
                .typography(.labelMedium)
                .foregroundStyle(isSelected ? .primary : .secondary)
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
                .foregroundStyle(isSelected ? .primary : .secondary)
                .scaleEffect(isSelected ? 1.0 : 0.9)
                .symbolEffect(.bounce, value: selection)
                .contentTransition(.symbolEffect(.replace))

        case .light:
            Image(systemName: "sun.max.fill")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .scaleEffect(isSelected ? 1.0 : 0.9)
                .symbolEffect(.variableColor.iterative, isActive: isSelected)
                .symbolEffect(.bounce, value: selection)
                .contentTransition(.symbolEffect(.replace))

        case .dark:
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .scaleEffect(isSelected ? 1.0 : 0.9)
                .symbolEffect(.bounce, value: selection)
                .contentTransition(.symbolEffect(.replace))
        }
    }
}

#Preview {
    @Previewable @State var mode: ThemeMode = .system

    AppearanceSelector(selection: $mode)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appSurface)
}
