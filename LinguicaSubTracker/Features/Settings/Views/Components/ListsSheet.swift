import SwiftUI

struct ListsSheet: View {
    @State private var viewModel: ListsViewModel
    @Environment(\.dismiss) private var dismiss

    init(settingsStore: SettingsStore) {
        _viewModel = State(
            initialValue: ListsViewModel(settingsStore: settingsStore)
        )
    }

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            VStack(spacing: 0) {
                List {
                    ForEach(vm.lists) { list in
                        row(for: list, vm: vm)
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
            .navigationTitle("Lists")
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
                ListEditView(listID: id, vm: vm)
            }
        }
        .sheet(isPresented: $vm.showColorPicker) {
            ColorPresetPicker(selectedHex: $vm.newColorHex)
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func row(for list: SubscriptionList, vm: ListsViewModel)
        -> some View
    {
        HStack {
            if vm.mode == .selecting {
                Image(
                    systemName: vm.selectedIDs.contains(list.id)
                        ? "checkmark.circle.fill" : "circle"
                )
                .foregroundStyle(
                    Color.purple.gradient
                )
            }
            Text(list.name)
                .typography(.bodyLarge)
                .foregroundStyle(.primary)
            Spacer()
            Circle()
                .fill(Color(hex: list.colorHex))
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
                if vm.isSelectable(list) { vm.toggleSelection(list.id) }
            case .editing:
                vm.editingID = list.id
            }
        }
    }

    @ViewBuilder
    private func addBar(vm: ListsViewModel) -> some View {
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

            TextField("New List", text: $vm.newName)
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

#Preview {
    ListsSheetPreviewHost()
}
