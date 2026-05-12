import SwiftUI

struct GlassSection<Content: View>: View {
    let content: Content
    var contentInsets: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
    var cornerRadius: CGFloat = 24
    var clipsContent: Bool = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)
        let base = VStack(spacing: 0) { content }
            .padding(contentInsets)
            .background(.ultraThinMaterial, in: shape)

        // Only clip when the caller opts in. Default leaves child shadows
        // free to render past the card edge.
        if clipsContent {
            base.clipShape(shape)
        } else {
            base
        }
    }
}

extension GlassSection {
    func contentInsets(_ insets: EdgeInsets) -> Self {
        var copy = self
        copy.contentInsets = insets
        return copy
    }

    func cornerRadius(_ radius: CGFloat) -> Self {
        var copy = self
        copy.cornerRadius = radius
        return copy
    }

    func clipsContent(_ value: Bool) -> Self {
        var copy = self
        copy.clipsContent = value
        return copy
    }
}
