import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    @Namespace private var glassNamespace // Required for morphing transitions

    var body: some View {
        // 1. Wrap the HStack in a GlassEffectContainer to enable blending
        GlassEffectContainer(spacing: 20) {
            HStack(spacing: 8) {
                
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
                // Use .interactive() for the "swelling" effect on touch
                .glassEffect(.regular.interactive(), in: Capsule())
                // Assign a unique ID within the namespace to enable morphing
                .glassEffectID("searchField", in: glassNamespace)

                // MARK: - Clear Button
                if isFocused || !text.isEmpty {
                    Button {
                        text = ""
                        isFocused = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.glass)
                    .glassEffect(.regular.interactive(), in: Circle())
                    // Matches this button to the search field for smooth morphing
                    .glassEffectID("clearButton", in: glassNamespace)
                    .glassEffectTransition(.matchedGeometry) // System default for morphing
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
