import SwiftUI

struct ExpensesInDay: View {
    private let store: AppStore
    private let coordinator: AppCoordinator
    @State private var viewModel: ExpensesInDayViewModel
    @State private var expensePendingDeletion: Expense?

    let settingsStore: SettingsStore

    init(
        date: Date,
        store: AppStore,
        settingsStore: SettingsStore,
        coordinator: AppCoordinator
    ) {
        self.store = store
        self.coordinator = coordinator
        self.settingsStore = settingsStore
        _viewModel = State(
            initialValue: ExpensesInDayViewModel(
                date: date,
                store: store,
                coordinator: coordinator
            )
        )
    }

    var body: some View {
        @Bindable var vm = viewModel
        // Direct observation hook so the day-sheet rebuilds when a new
        // expense is added on this date.
        let _ = store.expenses

        VStack(spacing: 0) {
            handle
            header

            ScrollView {
                VStack(spacing: 12) {
                    mainList(vm: vm)
                    totalBlock(vm: vm)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .appBackground()
        .presentationDetents([.height(viewModel.compactHeight)])
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $vm.showAddSheet) {
            SimplifiedAddExpenseView(
                date: vm.date,
                store: vm.store,
                settingsStore: settingsStore
            )
        }
        .confirmationDialog(
            "Delete \(expensePendingDeletion?.name ?? "")?",
            isPresented: deletionDialogBinding(),
            titleVisibility: .visible,
            presenting: expensePendingDeletion
        ) { expense in
            Button("Delete current", role: .destructive) {
                vm.deleteFromCurrentDay(expense)
                expensePendingDeletion = nil
            }
            Button("Delete all", role: .destructive) {
                vm.deleteAll(expense)
                expensePendingDeletion = nil
            }
            Button("Cancel", role: .cancel) {
                expensePendingDeletion = nil
            }
        } message: { _ in
            Text("Stop from this day forward, or remove the expense entirely.")
        }
    }

    private func deletionDialogBinding() -> Binding<Bool> {
        Binding(
            get: { expensePendingDeletion != nil },
            set: { if !$0 { expensePendingDeletion = nil } }
        )
    }

    private var handle: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.35))
            .frame(width: 36, height: 5)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }

    private var header: some View {
        VStack(spacing: 2) {
            Text("Expenses")
                .font(.headline)

            Text(viewModel.date, format: .dateTime.day().month(.wide).year())
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private func mainList(vm: ExpensesInDayViewModel) -> some View {
        let expenses = vm.expenses
        let rowHeight: CGFloat = 64
        let rowInsets = EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)

        GlassSection {
            VStack(spacing: 0) {
                if !expenses.isEmpty {
                    List {
                        ForEach(Array(expenses.enumerated()), id: \.element.id) { index, expense in
                            expenseTile(expense, vm: vm)
                                .listRowBackground(Color.clear)
                                .listRowInsets(rowInsets)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        expensePendingDeletion = expense
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollDisabled(true)
                    .scrollClipDisabled()
                    .frame(height: CGFloat(expenses.count) * rowHeight)
                }

                addRow(vm: vm)
                    .padding(rowInsets)
            }
        }
        .contentInsets(.init(top: 4, leading: 0, bottom: 4, trailing: 0))
    }

    private func expenseTile(
        _ expense: Expense,
        vm: ExpensesInDayViewModel
    ) -> some View {
        Button {
            vm.selectExpense(expense)
        } label: {
            HStack(spacing: 12) {
                LogoCircle(
                    size: 40,
                    customization: expense.logoCustomization(in: vm.store),
                    logoName: expense.logoName,
                    name: expense.name
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(expense.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(vm.rowSubtitle(for: expense))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func addRow(vm: ExpensesInDayViewModel) -> some View {
        Button {
            vm.showAddSheet = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(UIColor.tertiarySystemFill))
                        .frame(width: 40, height: 40)

                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                }

                Text("Add Expense")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()
            }
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func totalBlock(vm: ExpensesInDayViewModel) -> some View {
        GlassSection {
            HStack {
                Text("Total")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(vm.total, format: .currency(code: "CAD"))
                    .font(.subheadline.weight(.bold))
            }
            .frame(height: 44)
        }
    }
}

#Preview {
    ExpensesInDayPreviewHost()
}
