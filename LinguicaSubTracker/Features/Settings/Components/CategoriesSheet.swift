import SwiftUI

// MARK: - Categories Sheet

struct CategoriesSheet: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var newName: String = ""
    @State private var newColorHex: String = "#FF3B30"
    @State private var showColorPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    ForEach(settingsStore.settings.categories) { cat in
                        HStack {
                            Text(cat.name)
                                .typography(.bodyLarge)
                                .foregroundStyle(.primary)
                            Spacer()
                            Circle()
                                .fill(Color(hex: cat.colorHex))
                                .frame(width: 22, height: 22)
                        }
                        .padding(.vertical, 2)
                        .listRowBackground(Color.clear)
                    }
                    .onDelete { offsets in
                        settingsStore.deleteCategories(at: offsets)
                    }

                    if settingsStore.settings.categories.contains(where: { $0.isDefault }) {
                        Text("The 'Other' category cannot be deleted as it automatically serves as a default for subscriptions without a specific category.")
                            .typography(.bodySmall)
                            .foregroundStyle(.secondary)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)

                addBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
            }
            .navigationTitle("Categories")
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

            TextField("New Category", text: $newName)
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
        settingsStore.addCategory(newName, colorHex: newColorHex)
        newName = ""
    }
}

// MARK: - Color Preset Picker

struct ColorPresetPicker: View {
    @Binding var selectedHex: String
    @Environment(\.dismiss) private var dismiss

    private let presets: [String] = [
        "#FF3B30", "#FF6B00", "#FF9500", "#FFD60A",
        "#34C759", "#00C7BE", "#007AFF", "#5856D6",
        "#AF52DE", "#FF2D55", "#8E8E93", "#000000",
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 6)

    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Color")
                .typography(.titleMedium)
                .padding(.top, 16)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(presets, id: \.self) { hex in
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
                                        selectedHex == hex ? Color.white : Color.clear,
                                        lineWidth: 3
                                    )
                            )
                            .shadow(color: Color(hex: hex).opacity(0.5), radius: 4)
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

// MARK: - Previews

#Preview("Categories Sheet") {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            CategoriesSheet()
                .environmentObject(SettingsStore())
        }
}

#Preview("Color Preset Picker") {
    @Previewable @State var selectedHex: String = "#FF3B30"

    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ColorPresetPicker(selectedHex: $selectedHex)
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        }
}
