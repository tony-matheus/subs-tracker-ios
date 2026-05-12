import SwiftUI

struct ColorPresetPicker: View {
    @Binding var selectedHex: String
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ColorPresetPickerViewModel()

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 16),
        count: 6
    )

    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Color")
                .typography(.titleMedium)
                .padding(.top, 16)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.presets, id: \.self) { hex in
                    Button {
                        selectedHex = hex
                        dismiss()
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        viewModel.isSelected(hex, current: selectedHex)
                                            ? Color.white : Color.clear,
                                        lineWidth: 3
                                    )
                            )
                            .shadow(
                                color: Color(hex: hex).opacity(0.5),
                                radius: 4
                            )
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

#Preview {
    ColorPresetPickerPreviewHost()
}
