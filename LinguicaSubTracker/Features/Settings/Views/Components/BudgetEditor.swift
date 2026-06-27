import SwiftUI

struct BudgetEditor: View {
    private let settingsStore: SettingsStore
    private let store: AppStore
    @State private var viewModel: BudgetEditorViewModel

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

    /// Label tint matching the trailing end of the active gradient tier.
    private var progressColor: Color {
        return Color(white: 0.9)  // Default color

        //        switch viewModel.ratio {
        //        case ..<0.5: return Color(white: 0.9)
        //        case 0.5..<0.75: return .purple
        //        default: return .red
        //        }
    }

    private func clearButton(vm: BudgetEditorViewModel) -> some View {
        AppButton(
            icon: "eraser.fill",
            accessibilityTitle: "Clear",
            style: .secondary,
            appearance: .ghost,
            action: {
                withAnimation(
                    .spring(response: 0.3, dampingFraction: 0.8)
                ) {
                    vm.clearBudget()
                }
            }
        )
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

            HStack {
                if vm.overSpent {
                    HStack(spacing: 8) {
                        Text("Over spending")
                            .typography(.bodyMedium)
                            .foregroundStyle(.secondary)
                        Text(vm.overSpentAmount)
                            .typography(.bodyMedium)
                            .foregroundStyle(.red)
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                    .clipShape(Capsule())
                    .glassEffect()
                    .animation(
                        .easeInOut(duration: 0.4),
                        value: vm.overSpent
                    )
                }
                Spacer()
                Text(vm.formattedTotal)
                    .typography(.bodyMedium)
                    .foregroundStyle(progressColor)
                    .animation(
                        .easeInOut(duration: 0.4),
                        value: progressColor
                    )
            }

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
                    Button {
                        vm.prepareEdit()
                    } label: {
                        Text(vm.formattedBudget)
                            .typography(.headlineSmall)
                            .foregroundStyle(
                                vm.hasBudget ? .primary : .secondary
                            )
                            .contentTransition(.numericText())
                            .animation(
                                .spring(response: 0.35, dampingFraction: 0.8),
                                value: vm.formattedBudget
                            )
                    }
                    .buttonStyle(.plain)
                }

            }

            if vm.hasBudget {
                bugdetIndicator(vm: vm)
            }
        }
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
