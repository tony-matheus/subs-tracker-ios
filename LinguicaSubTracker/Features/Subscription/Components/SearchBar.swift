import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    @Namespace private var glassNamespace // Required for morphing transitions

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search", text: $text)
                .focused($isFocused)
                .textFieldStyle(.plain)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.7)))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .glassEffect(.regular.interactive(), in: Capsule())
        .animation(.spring(duration: 0.25, bounce: 0.2), value: text.isEmpty)
        .padding(.horizontal)
    }
}


#Preview {
    @Previewable @State var searchText: String = ""
    SearchBar(text: $searchText)
}
