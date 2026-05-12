import SwiftUI

struct ColorPresetPickerPreviewHost: View {
    @State private var selectedHex: String = "#FF3B30"

    var body: some View {
        Color.black.ignoresSafeArea()
            .sheet(isPresented: .constant(true)) {
                ColorPresetPicker(selectedHex: $selectedHex)
                    .presentationDetents([.height(320)])
                    .presentationDragIndicator(.visible)
            }
    }
}
