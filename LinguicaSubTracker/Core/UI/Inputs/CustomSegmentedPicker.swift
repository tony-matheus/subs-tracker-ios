import SwiftUI

// MARK: - CustomSegmentedPicker
//
// A segmented picker that accepts arbitrary leading / center / trailing
// content per segment. Mirrors the liquid-glass look of the native
// `Picker(.segmented)` via `.glassEffect(.regular, in: .rect(cornerRadius: AppRadius.card))` while
// allowing things native picker forbids — SF symbols, badges,
// emoji + text combos, etc.
//
// Usage:
//
//     CustomSegmentedPicker(
//         selection: $tab,
//         segments: [
//             .init(value: .photo,   leading: { Image(...) }, center: { Text("Photo") }),
//             .init(value: .emoji,   center: { Text("Emoji") }),
//             .init(value: .symbols, leading: { Image(...) }, center: { Text("Symbols") },
//                                    trailing: { badge }),
//         ]
//     )
struct CustomSegmentedPicker<Value: Hashable>: View {
    @Binding var selection: Value
    let segments: [CustomSegment<Value>]

    /// Spacing between leading/center/trailing inside one segment.
    var contentSpacing: CGFloat = 6
    /// Padding inside each segment's tappable area.
    var segmentPadding: EdgeInsets = .init(top: 8, leading: 12, bottom: 8, trailing: 12)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var highlightNS

    var body: some View {
        HStack(spacing: 4) {
            ForEach(segments) { segment in
                segmentContent(segment)
                    .background {
                        if selection == segment.value {
                            RoundedRectangle(cornerRadius: AppRadius.card)
                                .fill(Color.clear)
                                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: AppRadius.card))
                                .matchedGeometryEffect(id: "highlight", in: highlightNS)
                        }
                    }
            }
        }
        .padding(4)
        .background(Color.paperRaised, in: .rect(cornerRadius: AppRadius.card))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.card).strokeBorder(Color.rule))
        .contentShape(Rectangle())
        .overlay(
            GeometryReader { geo in
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onChanged { value in
                                updateSelection(at: value.location.x, width: geo.size.width)
                            }
                    )
            }
        )
        .animation(reduceMotion ? nil : .smooth(duration: 0.25), value: selection)
    }

    private func updateSelection(at x: CGFloat, width: CGFloat) {
        guard !segments.isEmpty else { return }
        // Outer padding(4) on each side; inner HStack uses spacing 4 but
        // for hit math we treat segments as equal slices of the inner band.
        let usable = max(1, width - 8)
        let clamped = min(max(0, x - 4), usable - 1)
        let segW = usable / CGFloat(segments.count)
        let idx = min(segments.count - 1, max(0, Int(clamped / segW)))
        let next = segments[idx].value
        if next != selection {
            selection = next
        }
    }

    @ViewBuilder
    private func segmentContent(_ segment: CustomSegment<Value>) -> some View {
        HStack(spacing: contentSpacing) {
            segment.leading
            segment.center
            segment.trailing
        }
        .lineLimit(1)
        .truncationMode(.tail)
        .frame(maxWidth: .infinity)
        .padding(segmentPadding)
        .contentShape(Rectangle())
    }
}

// MARK: - Segment model

struct CustomSegment<Value: Hashable>: Identifiable {
    let id = UUID()
    let value: Value
    let leading: AnyView
    let center: AnyView
    let trailing: AnyView

    init<L: View, C: View, T: View>(
        value: Value,
        @ViewBuilder leading: () -> L,
        @ViewBuilder center: () -> C,
        @ViewBuilder trailing: () -> T
    ) {
        self.value = value
        self.leading = AnyView(leading())
        self.center = AnyView(center())
        self.trailing = AnyView(trailing())
    }

    init<C: View>(
        value: Value,
        @ViewBuilder center: () -> C
    ) {
        self.init(value: value, leading: { EmptyView() }, center: center, trailing: { EmptyView() })
    }

    init<L: View, C: View>(
        value: Value,
        @ViewBuilder leading: () -> L,
        @ViewBuilder center: () -> C
    ) {
        self.init(value: value, leading: leading, center: center, trailing: { EmptyView() })
    }

    init<C: View, T: View>(
        value: Value,
        @ViewBuilder center: () -> C,
        @ViewBuilder trailing: () -> T
    ) {
        self.init(value: value, leading: { EmptyView() }, center: center, trailing: trailing)
    }
}

// MARK: - Previews

#Preview("Icons + text") {
    @Previewable @State var tab: Int = 0

    let iconColor = Color.ink

    CustomSegmentedPicker(
        selection: $tab,
        segments: [
            .init(value: 0,
                  leading: { Image(systemName: "photo.fill").foregroundStyle(iconColor) },
                  center:  { Text("Photo").typography(.bodyMedium) }),
            .init(value: 1,
                  leading: { Image(systemName: "face.smiling.inverse").foregroundStyle(iconColor) },
                  center:  { Text("Emoji").typography(.bodyMedium) }),
            .init(value: 2,
                  leading: { Image(systemName: "star.fill").foregroundStyle(iconColor) },
                  center:  { Text("Symbols").typography(.bodyMedium) }),
        ]
    )
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.paper)
}

#Preview("With trailing badge") {
    @Previewable @State var tab: String = "all"

    CustomSegmentedPicker(
        selection: $tab,
        segments: [
            .init(value: "all",
                  center: { Text("All").typography(.bodyMedium) },
                  trailing: {
                      Text("12")
                          .typography(.labelMedium)
                          .padding(.horizontal, 6)
                          .padding(.vertical, 2)
                          .background(Color.paperRaised, in: .rect(cornerRadius: AppRadius.card))
                  }),
            .init(value: "active",
                  center: { Text("Active").typography(.bodyMedium) }),
            .init(value: "paused",
                  center: { Text("Paused").typography(.bodyMedium) }),
        ]
    )
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.paper)
}
