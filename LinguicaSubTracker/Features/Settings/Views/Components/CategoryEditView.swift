import SwiftUI

struct CategoryEditView: View {
    let categoryID: UUID
    @Bindable var vm: CategoriesViewModel
    @State private var name: String = ""
    @State private var colorHex: String = "#FF3B30"
    @State private var showColorPicker = false

    var body: some View {
        Form {
            Section("Name") {
                TextField("Name", text: $name)
                    .typography(.bodyLarge)
                    .submitLabel(.done)
            }
            Section("Color") {
                Button {
                    showColorPicker = true
                } label: {
                    HStack {
                        Text("Color")
                            .typography(.bodyLarge)
                            .foregroundStyle(.primary)
                        Spacer()
                        Circle()
                            .fill(Color(hex: colorHex))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .strokeBorder(.white.opacity(0.3), lineWidth: 1.5)
                            )
                    }
                }
            }
        }
        .navigationTitle("Edit Category")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let c = vm.category(for: categoryID) {
                name = c.name
                colorHex = c.colorHex
            }
        }
        .onChange(of: name) { _, new in
            vm.rename(id: categoryID, name: new)
        }
        .onChange(of: colorHex) { _, new in
            vm.updateColor(id: categoryID, colorHex: new)
        }
        .sheet(isPresented: $showColorPicker) {
            ColorPresetPicker(selectedHex: $colorHex)
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        }
    }
}
