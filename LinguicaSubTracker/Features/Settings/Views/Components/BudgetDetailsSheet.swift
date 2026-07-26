import SwiftUI

/// Everything about the budget in one place: the general amount, how it splits
/// across categories, whether it is strict, and the reset/delete escapes.
/// Opened both from Settings and from the home list's budget CTA.
struct BudgetDetailsSheet: View {
    @State private var viewModel: BudgetDetailsViewModel
    @Environment(\.dismiss) private var dismiss

    init(settingsStore: SettingsStore, store: AppStore) {
        _viewModel = State(
            initialValue: BudgetDetailsViewModel(
                settingsStore: settingsStore,
                store: store
            )
        )
    }

    var body: some View {
        @Bindable var vm = viewModel

        // Read here so observation re-renders on every budget/expense change.
        let _ = vm.settingsStore.settings
        let _ = vm.store.expenses

        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header(vm: vm)
                    if vm.hasBudget {
                        modeSection(vm: vm)
                        categoriesSection(vm: vm)
                        actions(vm: vm)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .appBackground()
            .navigationTitle("Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: vm.hasBudget)
            .animation(.easeInOut(duration: 0.25), value: vm.allocated)
        }
        .sheet(item: $vm.editing) { _ in
            NumKeyPadSheet(
                amount: $vm.amount,
                currencyCode: $vm.currencyCode,
                typingStyle: .freeform
            ) {
                vm.commitEdit()
            }
            .presentationDetents([.height(560)])
            .presentationDragIndicator(.visible)
        }
        .alert("Delete budget?", isPresented: $vm.confirmingDelete) {
            Button("Delete", role: .destructive) {
                vm.deleteBudget()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The monthly amount and every category split are removed.")
        }
        .environment(vm.settingsStore)
    }

    // MARK: - Header

    private func header(vm: BudgetDetailsViewModel) -> some View {
        GlassSection {
            VStack(spacing: 12) {
                MoneyDisplay(
                    text: vm.formattedBudget,
                    size: 48,
                    tint: vm.isStrict && vm.isOverAllocated ? .red : .primary,
                    onTapGesture: { vm.beginEdit(.total) }
                )

                Text(vm.allocationSummary)
                    .typography(.bodySmall)
                    .foregroundStyle(vm.isStrict && vm.isOverAllocated ? .red : .secondary)
                    .contentTransition(.numericText())

                if vm.hasBudget {
                    allocationBar(vm: vm)
                } else {
                    // Way back to the keypad after cancelling it.
                    AppButton(
                        title: "Set budget",
                        icon: "plus",
                        style: .neutral,
                        appearance: .solid,
                        size: .large,
                        expands: true,
                        action: { vm.beginEdit(.total) }
                    )
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// How much of the budget is assigned, with the overflow drawn past the end.
    private func allocationBar(vm: BudgetDetailsViewModel) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.1))
                Capsule()
                    .fill(vm.isOverAllocated
                          ? (vm.isStrict ? Color.red : Color.orange)
                          : Color.appAccent)
                    .frame(width: geo.size.width * max(vm.allocationRatio, 0.02))
            }
        }
        .frame(height: 10)
    }

    // MARK: - Mode

    private func modeSection(vm: BudgetDetailsViewModel) -> some View {
        @Bindable var bindable = vm

        return LabeledSection("Rule") {
            Toggle(isOn: $bindable.isStrict) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Strict budget")
                        .typography(.bodyLarge)
                        .foregroundStyle(.primary)
                    Text(vm.isStrict
                         ? "Categories may not add up past the budget."
                         : "Categories may add up past the budget — it stretches to fit.")
                        .typography(.bodySmall)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

            if let warning = vm.warning {
                Divider()
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .iconStyle(size: 14, weight: .semibold, color: .red)
                    Text(warning)
                        .typography(.bodySmall)
                        .foregroundStyle(.red)
                }
                .padding(.top, 10)
                .transition(.opacity)
            }
        }
    }

    // MARK: - Categories

    private func categoriesSection(vm: BudgetDetailsViewModel) -> some View {
        let spends = vm.spendByCategory

        return LabeledSection("Categories") {
            ForEach(Array(vm.categories.enumerated()), id: \.element.id) { index, category in
                if index > 0 { Divider() }
                categoryRow(
                    vm: vm,
                    category: category,
                    spend: spends[category.name] ?? 0
                )
            }
        }
    }

    private func categoryRow(
        vm: BudgetDetailsViewModel,
        category: AppCategory,
        spend: Double
    ) -> some View {
        let slice = vm.budgetAmount(for: category.name)

        return Button {
            vm.beginEdit(.category(category.name))
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color(hex: category.colorHex))
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .typography(.bodyLarge)
                        .foregroundStyle(.primary)
                    Text("\(vm.formatted(spend)) spent")
                        .typography(.bodySmall)
                        .foregroundStyle(
                            vm.isOverspent(category.name, spend: spend) ? .red : .secondary
                        )
                }

                Spacer()

                Text(slice.map { vm.formatted($0) } ?? "Not set")
                    .typography(.bodyMedium.weight(.semibold))
                    .foregroundStyle(slice == nil ? .secondary : .primary)
                    .contentTransition(.numericText())
            }
            .frame(height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func actions(vm: BudgetDetailsViewModel) -> some View {
        VStack(spacing: 10) {
            AppButton(
                title: "Reset categories",
                icon: "arrow.counterclockwise",
                style: .neutral,
                appearance: .outline,
                size: .medium,
                expands: true,
                isDisabled: vm.allocated == 0,
                action: {
                    withAnimation { vm.resetCategories() }
                }
            )
            AppButton(
                title: "Delete budget",
                icon: "trash",
                style: .destructive,
                appearance: .ghost,
                size: .medium,
                expands: true,
                action: { vm.confirmingDelete = true }
            )
        }
    }
}

#Preview {
    BudgetEditorPreviewHost()
}
