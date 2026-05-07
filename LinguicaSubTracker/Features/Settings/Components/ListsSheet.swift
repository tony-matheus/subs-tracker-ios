import SwiftUI

struct ListsSheet: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var newName: String = ""
    @State private var newColorHex: String = "#007AFF"
    @State private var showColorPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    ForEach(settingsStore.settings.lists) { list in
                        HStack {
                            Text(list.name)
                                .typography(.bodyLarge)
                                .foregroundStyle(.primary)
                            Spacer()
                            Circle()
                                .fill(Color(hex: list.colorHex))
                                .frame(width: 22, height: 22)
                        }
                        .padding(.vertical, 2)
                        .listRowBackground(Color.clear)
                    }
                    .onDelete { offsets in
                        settingsStore.deleteLists(at: offsets)
                    }
                }
                .listStyle(.plain)

                addBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
            }
            .navigationTitle("Lists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .iconStyle(size: 13, weight: .semibold, color: .secondary)
                            .frame(width: 32, height: 32)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                        .typography(.bodyMedium)
                }
            }
        }
        .sheet(isPresented: $showColorPicker) {
            ColorPresetPicker(selectedHex: $newColorHex)
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        }
    }

    private var addBar: some View {
        HStack(spacing: 12) {
            Button {
                showColorPicker = true
            } label: {
                Circle()
                    .fill(Color(hex: newColorHex))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(0.3), lineWidth: 1.5)
                    )
            }

            TextField("New List", text: $newName)
                .typography(.bodyLarge)
                .submitLabel(.done)
                .onSubmit { commitAdd() }

            Button("Add") { commitAdd() }
                .typography(.titleSmall)
                .foregroundStyle(newName.isEmpty ? .secondary : .primary)
                .disabled(newName.isEmpty)
        }
        .frame(height: 44)
    }

    private func commitAdd() {
        settingsStore.addList(newName, colorHex: newColorHex)
        newName = ""
    }
}

#Preview {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ListsSheet()
                .environmentObject(SettingsStore())
        }
}
