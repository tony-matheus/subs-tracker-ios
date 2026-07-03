import SwiftUI

struct BudgetEditor: View {
    private let settingsStore: SettingsStore
    private let store: AppStore
    @State private var viewModel: BudgetEditorViewModel
    @State private var confirmingClear = false
    @State private var revertTask: Task<Void, Never>?

    init(settingsStore: SettingsStore, store: AppStore) {
        self.settingsStore = settingsStore
        self.store = store
        _viewModel = State(
            initialValue: BudgetEditorViewModel(
                settingsStore: settingsStore,
                store: store
            )
        )
    }

    private var progressGradient: LinearGradient {
        let base = BudgetColor.color(
            spent: viewModel.monthlyTotal,
            budget: settingsStore.settings.monthlyBudget
        )
        return LinearGradient(
            colors: [base.opacity(0.75), base],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Label tint matching the bar's active gradient tier.
    private var progressColor: Color {
        BudgetColor.color(
            spent: viewModel.monthlyTotal,
            budget: settingsStore.settings.monthlyBudget
        )
    }

    @ViewBuilder
    private func clearButton(vm: BudgetEditorViewModel) -> some View {
        if confirmingClear {
            Button {
                revertTask?.cancel()
                revertTask = nil
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    confirmingClear = false
                    vm.clearBudget()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .semibold))
                        .contentTransition(.symbolEffect(.replace))
                    Text("Clear?")
                        .typography(.bodySmall)
                }
                .foregroundStyle(.red)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.tint(.red.opacity(0.15)).interactive(), in: Capsule())
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        } else {
            AppButton(
                icon: "eraser.fill",
                accessibilityTitle: "Clear budget",
                style: .secondary,
                appearance: .ghost,
                action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        confirmingClear = true
                    }
                    revertTask?.cancel()
                    revertTask = Task { @MainActor in
                        try? await Task.sleep(for: .seconds(2))
                        guard !Task.isCancelled else { return }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            confirmingClear = false
                        }
                    }
                }
            )
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
    }

    private func bugdetIndicator(
        vm: BudgetEditorViewModel,
        height: CGFloat = 16
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: height)

                    Capsule()
                        .fill(progressGradient)
                        .frame(
                            width: geo.size.width * vm.ratio,
                            height: height
                        )
                        .animation(
                            .spring(
                                response: 0.5,
                                dampingFraction: 0.75
                            ),
                            value: vm.ratio
                        )
                }
            }
            .frame(height: height)
            .background(Color.appSurface)

            HStack(alignment: .top) {
                statColumn(
                    label: "Spent",
                    value: vm.formattedTotal,
                    color: progressColor,
                    alignment: .leading
                )

                Spacer()

                if vm.overSpent {
                    statColumn(
                        label: "Over by",
                        value: vm.overSpentAmount,
                        color: .red,
                        alignment: .center
                    )
                } else {
                    statColumn(
                        label: "Remaining",
                        value: vm.formattedRemaining,
                        color: .primary,
                        alignment: .center
                    )
                }

                Spacer()

                statColumn(
                    label: "Budget",
                    value: vm.formattedBudget,
                    color: .secondary,
                    alignment: .trailing
                )
            }
            .animation(.easeInOut(duration: 0.4), value: vm.overSpent)

        }
    }

    private func statColumn(
        label: String,
        value: String,
        color: Color,
        alignment: HorizontalAlignment
    ) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(label)
                .typography(.labelMedium)
                .foregroundStyle(.secondary)
            Text(value)
                .typography(.bodyMedium.weight(.semibold))
                .foregroundStyle(color)
                .contentTransition(.numericText())
        }
    }

    var body: some View {
        @Bindable var vm = viewModel

        let _ = settingsStore.settings.monthlyBudget
        let _ = settingsStore.settings.currencyCode
        let _ = store.expenses

        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {

                        HStack {
                            Image(systemName: "wallet.bifold.fill")
                                .iconStyle(
                                    size: 16,
                                    weight: .semibold,
                                    color: .secondary
                                )
                            Text("Monthly Budget")
                                .typography(.bodyLarge)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        Spacer()

                        if vm.hasBudget {
                            clearButton(vm: vm)
                        }
                    }
                    if vm.hasBudget {
                        Button {
                            vm.prepareEdit()
                        } label: {
                            Text(vm.formattedBudget)
                                .typography(.headlineSmall)
                                .foregroundStyle(.primary)
                                .contentTransition(.numericText())
                                .animation(
                                    .spring(response: 0.35, dampingFraction: 0.8),
                                    value: vm.formattedBudget
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

            }

            if vm.hasBudget {
                bugdetIndicator(vm: vm)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            } else {
                AppButton(
                    title: "Set a monthly budget",
                    icon: "plus",
                    style: .neutral,
                    appearance: .glassy,
                    size: .medium,
                    expands: true,
                    action: { vm.prepareEdit() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .animation(
            .spring(response: 0.35, dampingFraction: 0.85),
            value: vm.hasBudget
        )
        .sheet(isPresented: $vm.showKeypad) {
            NumKeyPadSheet(
                amount: $vm.budgetAmount,
                currencyCode: $vm.currencyCode,
                typingStyle: .freeform
            ) {
                vm.applyKeypadAmount()
            }
            .presentationDetents([.height(560)])
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    BudgetEditorPreviewHost()
}
