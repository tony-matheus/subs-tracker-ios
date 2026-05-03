import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    @Namespace private var glassNamespace // Required for morphing transitions

    var body: some View {
        // 1. Wrap the HStack in a GlassEffectContainer to enable blending
        GlassEffectContainer(spacing: 20) {
            HStack(spacing: 16) {

                // MARK: - Search Field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search", text: $text)
                        .focused($isFocused)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 16)
                .frame(height: 54)
                .glassEffect(.regular.interactive(), in: Capsule())
                .glassEffectID("searchField", in: glassNamespace)

                if isFocused || !text.isEmpty {
                    Button {
                        text = ""
                        isFocused = false
                    } label: {
                        Image(systemName: "xmark")
                            .iconStyle(size: 14, weight: .bold)
                            .frame(width: 54, height: 54)
                    }
                    .buttonStyle(.liquidGlass)
                    .glassEffectID("clearButton", in: glassNamespace)
                    .glassEffectTransition(.matchedGeometry)
                    .transition(.opacity)
                }
            }
        }
        .animation(.spring(duration: 0.35, bounce: 0.3), value: isFocused)
        .padding(.horizontal)
    }
}


#Preview {
    @Previewable @State var searchText: String = ""
    SearchBar(text: $searchText)
}
