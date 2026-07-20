import SwiftUI

struct CategoriesSheet: View {
    @State private var viewModel: CategoriesViewModel
    @Environment(\.dismiss) private var dismiss

    init(settingsStore: SettingsStore) {
        _viewModel = State(
            initialValue: CategoriesViewModel(settingsStore: settingsStore)
        )
    }

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            VStack(spacing: 0) {
                List {
                    ForEach(vm.categories) { cat in
                        row(for: cat, vm: vm)
                    }

                    if vm.hasDefaultCategory {
                        Text(
                            "The 'Other' category cannot be deleted as it automatically serves as a default for expenses without a specific category."
                        )
                        .typography(.bodySmall)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)

                if vm.mode == .viewing {
                    addBar(vm: vm)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                RowModeToolbar(
                    mode: vm.mode,
                    hasSelection: !vm.selectedIDs.isEmpty,
                    onDismiss: { dismiss() },
                    onEnterEdit: { vm.enterEditMode() },
                    onEnterSelect: { vm.enterSelectMode() },
                    onDeleteSelected: {
                        vm.deleteSelected()
                        vm.exitMode()
                    },
                    onDone: { vm.exitMode() }
                )
            }
            .navigationDestination(item: $vm.editingID) { id in
                CategoryEditView(categoryID: id, vm: vm)
            }
        }
        .sheet(isPresented: $vm.showColorPicker) {
            ColorPresetPicker(selectedHex: $vm.newColorHex)
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func row(for cat: AppCategory, vm: CategoriesViewModel) -> some View {
        HStack {
            if vm.mode == .selecting {
                Image(
                    systemName: vm.selectedIDs.contains(cat.id)
                        ? "checkmark.circle.fill" : "circle"
                )
                .foregroundStyle(
                    vm.isSelectable(cat) ? Color.appAccent : Color.secondary.opacity(0.4)
                )
            }
            Text(cat.name)
                .typography(.bodyLarge)
                .foregroundStyle(.primary)
            Spacer()
            Circle()
                .fill(Color(hex: cat.colorHex))
                .frame(width: 22, height: 22)
            if vm.mode == .editing {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .listRowBackground(Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            switch vm.mode {
            case .viewing:
                break
            case .selecting:
                if vm.isSelectable(cat) { vm.toggleSelection(cat.id) }
            case .editing:
                vm.editingID = cat.id
            }
        }
    }

    @ViewBuilder
    private func addBar(vm: CategoriesViewModel) -> some View {
        @Bindable var vm = vm
        HStack(spacing: 12) {
            Button {
                vm.showColorPicker = true
            } label: {
                Circle()
                    .fill(Color(hex: vm.newColorHex))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(0.3), lineWidth: 1.5)
                    )
            }

            TextField("New Category", text: $vm.newName)
                .typography(.bodyLarge)
                .submitLabel(.done)
                .onSubmit { vm.commitAdd() }

            Button("Add") { vm.commitAdd() }
                .typography(.titleSmall)
                .foregroundStyle(vm.canAdd ? .primary : .secondary)
                .disabled(!vm.canAdd)
        }
        .frame(height: 44)
    }
}

#Preview("Categories Sheet") {
    CategoriesSheetPreviewHost()
}
