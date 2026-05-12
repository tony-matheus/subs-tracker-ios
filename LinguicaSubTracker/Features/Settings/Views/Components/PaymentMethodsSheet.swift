import SwiftUI

struct PaymentMethodsSheet: View {
    @State private var viewModel: PaymentMethodsViewModel
    @Environment(\.dismiss) private var dismiss

    init(settingsStore: SettingsStore) {
        _viewModel = State(initialValue: PaymentMethodsViewModel(settingsStore: settingsStore))
    }

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            VStack(spacing: 0) {
                List {
                    ForEach(vm.paymentMethods) { method in
                        row(for: method, vm: vm)
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
            .navigationTitle("Payment Methods")
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
                PaymentMethodEditView(methodID: id, vm: vm)
            }
        }
    }

    @ViewBuilder
    private func row(for method: PaymentMethod, vm: PaymentMethodsViewModel) -> some View {
        HStack {
            if vm.mode == .selecting {
                Image(
                    systemName: vm.selectedIDs.contains(method.id)
                        ? "checkmark.circle.fill" : "circle"
                )
                .foregroundStyle(
                    vm.isSelectable(method) ? Color.purple : Color.secondary.opacity(0.4)
                )
            }
            Text(method.name)
                .typography(.bodyLarge)
                .foregroundStyle(.primary)
            Spacer()
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
                if vm.isSelectable(method) { vm.toggleSelection(method.id) }
            case .editing:
                vm.editingID = method.id
            }
        }
    }

    @ViewBuilder
    private func addBar(vm: PaymentMethodsViewModel) -> some View {
        @Bindable var vm = vm
        HStack(spacing: 12) {
            TextField("New Payment Method", text: $vm.newName)
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
    PaymentMethodsSheetPreviewHost()
}
