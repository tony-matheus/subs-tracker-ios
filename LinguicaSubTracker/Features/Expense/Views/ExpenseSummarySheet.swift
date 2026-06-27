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

            Text(vm.expense.name)
                .font(.title.weight(.bold))

            Text(vm.scheduleAndPriceText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }

    private func detailsBlock(vm: ExpenseSummaryViewModel) -> some View {
        GlassSection {
            FormRow(label: "Amount") {
                Text(vm.expense.price, format: .currency(code: "CAD"))
                    .font(.subheadline)
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
                Text(vm.typeLabel)
                    .font(.subheadline)
            }
        }
    }

    private func categoryBlock(vm: ExpenseSummaryViewModel) -> some View {
        GlassSection {
            FormRow(label: "Category") {
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

    private func listBlock(vm: ExpenseSummaryViewModel) -> some View {
        GlassSection {
            FormRow(label: "List") {
                Text(vm.expense.list)
                    .font(.subheadline)
            }
        }
    }
}

#Preview {
    ExpenseSummarySheetPreviewHost()
}
