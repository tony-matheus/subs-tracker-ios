import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    init(settingsStore: SettingsStore, store: AppStore) {
        _viewModel = State(
            initialValue: SettingsViewModel(
                settingsStore: settingsStore,
                store: store
            )
        )
    }

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    appearancePreferences(vm: vm)
                    numberPreferences(vm: vm)
                    filtersPreferences(vm: vm)
                    GlassSection {
                        BudgetEditor(
                            settingsStore: vm.settingsStore,
                            store: vm.store
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .appBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }

                }
            }
        }
        .sheet(isPresented: $vm.showCurrencyPicker) {
            CurrencyPickerSheet(settingsStore: vm.settingsStore)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $vm.showCategories) {
            CategoriesSheet(settingsStore: vm.settingsStore)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $vm.showPaymentMethods) {
            PaymentMethodsSheet(settingsStore: vm.settingsStore)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $vm.showLists) {
            ListsSheet(settingsStore: vm.settingsStore)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func appearancePreferences(vm: SettingsViewModel) -> some View {
        GlassSection {
            VStack(alignment: .leading, spacing: 12) {
                Text("Appearance")
                    .typography(.bodyLarge)
                    .foregroundStyle(.primary)

                Picker("Appearance", selection: vm.themeModeBinding()) {
                    ForEach(ThemeMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private func numberPreferences(vm: SettingsViewModel) -> some View {
        GlassSection {
            Button {
                vm.showCurrencyPicker = true
            } label: {
                HStack {
                    Text("Main Currency")
                        .typography(.bodyLarge)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(vm.currencyCode)
                        .typography(.bodyMedium)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .iconStyle(
                            size: 12,
                            weight: .semibold,
                            color: .secondary
                        )
                }
                .frame(height: 44)
            }
            .buttonStyle(.plain)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Toggle(isOn: vm.roundAmountsBinding()) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rounding")
                            .typography(.bodyLarge)
                            .foregroundStyle(.primary)
                        Text("Display amounts without decimals")
                            .typography(.bodySmall)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .green))
            }
            .padding(.vertical, 8)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Toggle(isOn: vm.abbreviateLargeNumbersBinding()) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Abbreviate Large Numbers")
                            .typography(.bodyLarge)
                            .foregroundStyle(.primary)
                        Text("Use compact format like 74.5k")
                            .typography(.bodySmall)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .green))
            }
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private func filtersPreferences(vm: SettingsViewModel) -> some View {
        GlassSection {
            filterRow(
                icon: "square.grid.2x2",
                title: "Categories",
                count: vm.categoriesCount
            ) { vm.showCategories = true }

            Divider()

            filterRow(
                icon: "creditcard",
                title: "Payment Methods",
                count: vm.paymentMethodsCount
            ) { vm.showPaymentMethods = true }

            Divider()

            filterRow(
                icon: "list.dash",
                title: "Lists",
                count: vm.listsCount
            ) { vm.showLists = true }
        }
    }

    private func filterRow(
        icon: String,
        title: String,
        count: Int,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .iconStyle(size: 16, weight: .medium, color: .secondary)
                    .frame(width: 24)
                Text(title)
                    .typography(.bodyLarge)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(count)")
                    .typography(.bodyMedium)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .iconStyle(size: 12, weight: .semibold, color: .secondary)
            }
            .frame(height: 44)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsViewPreviewHost()
}
