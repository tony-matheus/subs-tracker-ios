import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteDataAlert = false
    @State private var showResetAppAlert = false
    // Gates the footer heart's repeating bounce so it only animates while
    // actually scrolled into view (it lives at the bottom of the scroll).
    @State private var isFooterVisible = false

    init(settingsStore: SettingsStore, store: AppStore, coordinator: AppCoordinator) {
        _viewModel = State(
            initialValue: SettingsViewModel(
                settingsStore: settingsStore,
                store: store,
                coordinator: coordinator
            )
        )
    }

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            ScrollView {
                // Grouped by task, most-used first (budget), destructive
                // actions last — one labeled section per concern.
                VStack(spacing: 24) {
                    section("Budget") {
                        GlassSection {
                            BudgetEditor(
                                settingsStore: vm.settingsStore,
                                store: vm.store
                            )
                        }
                    }
                    section("Money & Display") { numberPreferences(vm: vm) }
                    section("Organize") { filtersPreferences(vm: vm) }
                    section("Appearance") { appearancePreferences(vm: vm) }
                    section("Privacy & Data") { aboutSection(vm: vm) }
                    section("Danger Zone") { dangerZone(vm: vm) }
                    VStack(spacing: 8) {
                        HStack {
                            Text("Made with")
                            Image(systemName: "suit.heart.fill")
                                .symbolEffect(
                                    .bounce.up.byLayer,
                                    options: .repeat(.periodic(delay: 0.3)),
                                    isActive: isFooterVisible
                                )
                                .foregroundStyle(.red)
                            Text("by")
                            Link(
                                "@tony_linguica",
                                destination: URL(string: "x.com/tony_linguica")!
                            )
                        }
                        .typography(.titleSmall)
                        .foregroundStyle(.secondary)
                        HStack {
                            Text("version: 0.0.1")
                                .typography(.bodySmall)
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    .onScrollVisibilityChange(threshold: 0.2) { visible in
                        isFooterVisible = visible
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .appBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                #if DEBUG
                // Headless-testing hook (same pattern as ONBOARDING_PAGE):
                // SIMCTL_CHILD_DEBUG_OPEN_SETTINGS_PAGE=privacy|datainfo|calendarstyle
                switch ProcessInfo.processInfo.environment["DEBUG_OPEN_SETTINGS_PAGE"] {
                case "privacy": viewModel.showPrivacy = true
                case "datainfo": viewModel.showDataInfo = true
                case "calendarstyle": viewModel.showCalendarStyle = true
                default: break
                }
                #endif
            }
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
        .sheet(isPresented: $vm.showCalendarStyle) {
            CalendarStyleSheet(settingsStore: vm.settingsStore)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $vm.showPrivacy) {
            PrivacySheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $vm.showDataInfo) {
            DataInfoSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert("Delete All Data?", isPresented: $showDeleteDataAlert) {
            Button("Delete", role: .destructive) {
                viewModel.deleteAllExpenses()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes all \(viewModel.expensesCount) expenses and their logos. Categories, payment methods, lists, budget and appearance stay as configured. This can't be undone.")
        }
        .alert("Reset App Completely?", isPresented: $showResetAppAlert) {
            Button("Reset", role: .destructive) {
                viewModel.resetAppCompletely()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes every expense, category, payment method, list and preference, then restarts onboarding as if freshly installed. This can't be undone.")
        }
    }

    /// Section title + content, spaced per the app's settings grouping style.
    private func section(
        _ title: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .typography(.labelLarge)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
            content()
        }
    }

    @ViewBuilder
    private func appearancePreferences(vm: SettingsViewModel) -> some View {
        GlassSection {
            VStack(alignment: .leading, spacing: 12) {
                AppearanceSelector(selection: vm.themeModeBinding())

                Divider()

                detailRow(
                    icon: "calendar",
                    title: "Calendar Style",
                    detail: vm.calendarStyleName
                ) { vm.showCalendarStyle = true }
            }
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private func aboutSection(vm: SettingsViewModel) -> some View {
        GlassSection {
            detailRow(
                icon: "hand.raised",
                title: "Privacy",
                detail: ""
            ) { vm.showPrivacy = true }

            Divider()

            detailRow(
                icon: "internaldrive",
                title: "How My Data Is Saved",
                detail: ""
            ) { vm.showDataInfo = true }
        }
    }

    @ViewBuilder
    private func numberPreferences(vm: SettingsViewModel) -> some View {
        GlassSection {
            Button {
                vm.showCurrencyPicker = true
            } label: {
                HStack {
                    Image(systemName: "banknote.fill")
                        .iconStyle(size: 16, weight: .medium, color: .secondary)
                        .frame(width: 24)
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
                    HStack(spacing: 10) {
                        Image(systemName: "0.circle.fill")
                            .iconStyle(
                                size: 16,
                                weight: .medium,
                                color: .secondary
                            )
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rounding")
                                .typography(.bodyLarge)
                                .foregroundStyle(.primary)
                            Text("Display amounts without decimals")
                                .typography(.bodySmall)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .green))
            }
            .padding(.vertical, 8)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Toggle(isOn: vm.abbreviateLargeNumbersBinding()) {
                    HStack(spacing: 10) {
                        Image(systemName: "k.circle.fill")
                            .iconStyle(
                                size: 16,
                                weight: .medium,
                                color: .secondary
                            )
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Abbreviate Large Numbers")
                                .typography(.bodyLarge)
                                .foregroundStyle(.primary)
                            Text("Use compact format like 74.5k")
                                .typography(.bodySmall)
                                .foregroundStyle(.secondary)
                        }
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

    @ViewBuilder
    private func dangerZone(vm: SettingsViewModel) -> some View {
        GlassSection {
            VStack(alignment: .leading, spacing: 12) {
                AppButton(
                    title: "Delete All Data",
                    icon: "trash",
                    style: .destructive,
                    appearance: .glassy,
                    size: .medium,
                    expands: true,
                    action: { showDeleteDataAlert = true }
                )

                AppButton(
                    title: "Reset App Completely",
                    icon: "arrow.counterclockwise",
                    style: .destructive,
                    appearance: .glassy,
                    size: .medium,
                    expands: true,
                    action: { showResetAppAlert = true }
                )
            }
            .padding(.vertical, 8)
        }
    }

    private func filterRow(
        icon: String,
        title: String,
        count: Int,
        action: @escaping () -> Void
    ) -> some View {
        detailRow(icon: icon, title: title, detail: "\(count)", action: action)
    }

    /// Disclosure row: icon + title, optional detail text, chevron.
    private func detailRow(
        icon: String,
        title: String,
        detail: String,
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
                if !detail.isEmpty {
                    Text(detail)
                        .typography(.bodyMedium)
                        .foregroundStyle(.secondary)
                }
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
