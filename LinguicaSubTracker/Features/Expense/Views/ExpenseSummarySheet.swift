import SwiftUI

struct ExpenseSummarySheet: View {
    @State private var viewModel: ExpenseSummaryViewModel
    let settingsStore: SettingsStore

    init(expense: Expense, store: AppStore, settingsStore: SettingsStore, coordinator: AppCoordinator) {
        self.settingsStore = settingsStore
        _viewModel = State(initialValue: ExpenseSummaryViewModel(expense: expense, store: store, coordinator: coordinator))
    }

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    logoUI(vm: vm, size: 130)
                    .blur(radius:50)
                    Spacer()
                }

                ScrollView {
                    VStack(spacing: 16) {
                        heroSection(vm: vm)
                        detailsBlock(vm: vm)
                        typeBlock(vm: vm)
                        categoryBlock(vm: vm)
                        listBlock(vm: vm)
                        Spacer(minLength: 88)
                    }
                    .padding()
                }

                deleteButton(vm: vm)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { summaryToolbar(vm: vm) }
        }
        .presentationBackground(.ultraThinMaterial)
        .presentationDragIndicator(.visible)
        .onAppear {
            vm.currencyCode = settingsStore.settings.currencyCode
        }
        .alert("Delete Expense", isPresented: $vm.showDeleteAlert) {
            Button("Delete", role: .destructive) { vm.confirmDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(vm.expense.name) will be permanently removed.")
        }
        .sheet(isPresented: $vm.showEdit) {
            ExpenseFormView(
                mode: .edit(vm.expense),
                store: vm.store,
                settingsStore: settingsStore,
                onCommit: { updated in vm.applyEdit(updated) }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $vm.quickEdit) { field in
            quickEditSheet(vm: vm, field: field)
        }
    }

    private func logoUI (vm: ExpenseSummaryViewModel, size: CGFloat = 72) -> some View {
        LogoCircle(
            size: size,
            customization: vm.customization,
            logoName: vm.logoName,
            name: vm.expense.name
        )
    }

    @ToolbarContentBuilder
    private func summaryToolbar(vm: ExpenseSummaryViewModel) -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Button("Active") { vm.setActive(true) }
                Button("Inactive") { vm.setActive(false) }
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(vm.isActive ? .green : .gray)
                        .frame(width: 8, height: 8)
                    Text(vm.isActive ? "Active" : "Inactive")
                        .font(.subheadline.weight(.medium))
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .clipShape(Capsule())
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                vm.showEdit = true
            } label: {
                Image(systemName: "pencil")
            }
            .tint(.green)
        }
    }

    @ViewBuilder
    private func deleteButton(vm: ExpenseSummaryViewModel) -> some View {
        AppButton(
            title: "Delete Expense",
            icon: "trash",
            style: .destructive,
            size: .large,
            expands: true,
            action: { vm.showDeleteAlert = true }
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private func heroSection(vm: ExpenseSummaryViewModel) -> some View {
        VStack(spacing: 10) {
            logoUI(vm: vm)
            .padding(.top, 8)

            Button {
                vm.beginQuickEdit(.name)
            } label: {
                Text(vm.expense.name)
                    .font(.title.weight(.bold))
                    .contentTransition(.numericText())
            }
            .buttonStyle(.plain)

            Text(vm.scheduleAndPriceText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }

    /// Row value wrapped in a subtle tap affordance for quick edits.
    private func editableValue<Content: View>(
        vm: ExpenseSummaryViewModel,
        field: QuickEditField,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Button {
            vm.beginQuickEdit(field)
        } label: {
            HStack(spacing: 6) {
                content()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func detailsBlock(vm: ExpenseSummaryViewModel) -> some View {
        GlassSection {
            FormRow(label: "Amount") {
                editableValue(vm: vm, field: .amount) {
                    Text(vm.expense.price, format: .currency(code: "CAD"))
                        .font(.subheadline)
                        .contentTransition(.numericText())
                }
            }

            Divider()

            FormRow(label: "Next payment") {
                Text(vm.nextPaymentText)
                    .font(.caption)
                    .multilineTextAlignment(.trailing)
            }

            Divider()

            FormRow(label: "Total spent") {
                Text(vm.totalSpent, format: .currency(code: "CAD"))
                    .font(.subheadline)
            }
        }
    }

    private func typeBlock(vm: ExpenseSummaryViewModel) -> some View {
        GlassSection {
            FormRow(label: "Type") {
                editableValue(vm: vm, field: .type) {
                    Text(vm.typeLabel)
                        .font(.subheadline)
                }
            }
        }
    }

    private func categoryBlock(vm: ExpenseSummaryViewModel) -> some View {
        GlassSection {
            FormRow(label: "Category") {
                editableValue(vm: vm, field: .category) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(vm.themeColor)
                            .frame(width: 10, height: 10)
                        Text(vm.expense.category)
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    private func listBlock(vm: ExpenseSummaryViewModel) -> some View {
        GlassSection {
            FormRow(label: "List") {
                editableValue(vm: vm, field: .list) {
                    Text(vm.expense.list)
                        .font(.subheadline)
                }
            }
        }
    }

    // MARK: - Quick-edit modals

    @ViewBuilder
    private func quickEditSheet(vm: ExpenseSummaryViewModel, field: QuickEditField) -> some View {
        @Bindable var vm = vm

        switch field {
        case .name:
            QuickNameSheet(name: $vm.draftName) {
                vm.commitQuickName()
            }

        case .amount:
            NumKeyPadSheet(
                amount: $vm.draftAmount,
                currencyCode: $vm.currencyCode,
                typingStyle: .decimal
            ) {
                vm.commitQuickAmount()
            }
            .environment(settingsStore)
            .presentationDetents([.height(560)])
            .presentationDragIndicator(.visible)

        case .category:
            QuickPickSheet(
                title: "Category",
                options: settingsStore.settings.categories.map {
                    (value: $0.name, label: $0.name, color: Color(hex: $0.colorHex))
                },
                selected: vm.expense.category
            ) { vm.quickSet(category: $0) }

        case .list:
            QuickPickSheet(
                title: "List",
                options: settingsStore.settings.lists.map {
                    (value: $0.name, label: $0.name, color: Color(hex: $0.colorHex))
                },
                selected: vm.expense.list
            ) { vm.quickSet(list: $0) }

        case .type:
            QuickPickSheet(
                title: "Type",
                options: ExpenseType.allCases.map {
                    (value: $0.rawValue, label: $0.displayName, color: nil)
                },
                selected: vm.expense.type.rawValue
            ) { raw in
                if let type = ExpenseType(rawValue: raw) {
                    vm.quickSet(type: type)
                }
            }
        }
    }
}

/// Tiny single-field name editor.
private struct QuickNameSheet: View {
    @Binding var name: String
    let onCommit: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Name")
                .typography(.titleMedium)
                .foregroundStyle(.secondary)

            TextField("Expense name", text: $name)
                .multilineTextAlignment(.center)
                .typography(.headlineMedium)
                .focused($focused)
                .submitLabel(.done)
                .onSubmit { onCommit() }

            AppButton(
                title: "Save",
                style: .neutral,
                appearance: .solid,
                size: .medium,
                expands: true,
                action: onCommit
            )
        }
        .padding(24)
        .presentationDetents([.height(230)])
        .presentationDragIndicator(.visible)
        .onAppear { focused = true }
    }
}

/// Tiny option picker: color dot + label + checkmark, tap selects and closes.
private struct QuickPickSheet: View {
    let title: String
    let options: [(value: String, label: String, color: Color?)]
    let selected: String
    let onSelect: (String) -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text(title)
                .typography(.titleMedium)
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                ForEach(options, id: \.value) { option in
                    optionRow(option)
                }
            }
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents([
            .height(min(CGFloat(options.count) * 52 + 92, 460))
        ])
        .presentationDragIndicator(.visible)
    }

    private func optionRow(_ option: (value: String, label: String, color: Color?)) -> some View {
        let isSelected = option.value == selected

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onSelect(option.value)
        } label: {
            HStack(spacing: 10) {
                if let color = option.color {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)
                }
                Text(option.label)
                    .typography(.bodyLarge.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .iconStyle(size: 14, weight: .semibold, color: .primary)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.primary.opacity(0.08) : Color.clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ExpenseSummarySheetPreviewHost()
}
