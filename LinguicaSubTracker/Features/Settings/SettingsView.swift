import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var showCurrencyPicker = false
    @State private var showCategories = false
    @State private var showPaymentMethods = false
    @State private var showLists = false

    private var settings: AppSettings { settingsStore.settings }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    block1
                    block2
                    block3
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .iconStyle(size: 13, weight: .semibold, color: .secondary)
                            .frame(width: 32, height: 32)
                    }
                }
            }
        }
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet()
                .environmentObject(settingsStore)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCategories) {
            CategoriesSheet()
                .environmentObject(settingsStore)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPaymentMethods) {
            PaymentMethodsSheet()
                .environmentObject(settingsStore)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showLists) {
            ListsSheet()
                .environmentObject(settingsStore)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Block 1: Preferences

    private var block1: some View {
        GlassSection {
            Button {
                showCurrencyPicker = true
            } label: {
                HStack {
                    Text("Main Currency")
                        .typography(.bodyLarge)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(settings.currencyCode)
                        .typography(.bodyMedium)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .iconStyle(size: 12, weight: .semibold, color: .secondary)
                }
                .frame(height: 44)
            }
            .buttonStyle(.plain)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Toggle(isOn: $settingsStore.settings.roundAmounts) {
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
                Toggle(isOn: $settingsStore.settings.abbreviateLargeNumbers) {
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

    // MARK: - Block 2: Categories, Payment Methods, Lists

    private var block2: some View {
        GlassSection {
            Button {
                showCategories = true
            } label: {
                HStack {
                    Image(systemName: "square.grid.2x2")
                        .iconStyle(size: 16, weight: .medium, color: .secondary)
                        .frame(width: 24)
                    Text("Categories")
                        .typography(.bodyLarge)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(settings.categories.count)")
                        .typography(.bodyMedium)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .iconStyle(size: 12, weight: .semibold, color: .secondary)
                }
                .frame(height: 44)
            }
            .buttonStyle(.plain)

            Divider()

            Button {
                showPaymentMethods = true
            } label: {
                HStack {
                    Image(systemName: "creditcard")
                        .iconStyle(size: 16, weight: .medium, color: .secondary)
                        .frame(width: 24)
                    Text("Payment Methods")
                        .typography(.bodyLarge)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(settings.paymentMethods.count)")
                        .typography(.bodyMedium)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .iconStyle(size: 12, weight: .semibold, color: .secondary)
                }
                .frame(height: 44)
            }
            .buttonStyle(.plain)

            Divider()

            Button {
                showLists = true
            } label: {
                HStack {
                    Image(systemName: "list.dash")
                        .iconStyle(size: 16, weight: .medium, color: .secondary)
                        .frame(width: 24)
                    Text("Lists")
                        .typography(.bodyLarge)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(settings.lists.count)")
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

    // MARK: - Block 3: Budget

    private var block3: some View {
        GlassSection {
            BudgetEditor()
                .environmentObject(settingsStore)
                .environmentObject(store)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsStore())
        .environmentObject(AppStore())
        .preferredColorScheme(.dark)
}
