import SwiftUI

struct ListEditView: View {
    let listID: UUID
    @Bindable var vm: ListsViewModel
    @State private var name: String = ""
    @State private var colorHex: String = "#007AFF"
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
                            .foregroundStyle(Color.ink)
                        Spacer()
                        Circle()
                            .fill(Color(hex: colorHex))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.rule, lineWidth: 1)
                            )
                    }
                }
            }
        }
        .navigationTitle("Edit List")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let l = vm.list(for: listID) {
                name = l.name
                colorHex = l.colorHex
            }
        }
        .onChange(of: name) { _, new in
            vm.rename(id: listID, name: new)
        }
        .onChange(of: colorHex) { _, new in
            vm.updateColor(id: listID, colorHex: new)
        }
        .sheet(isPresented: $showColorPicker) {
            ColorPresetPicker(selectedHex: $colorHex)
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        }
    }
}
