import CloudKit
import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteDataAlert = false
    @State private var showResetAppAlert = false
    /// Same key `CloudSyncService.isEnabled` reads.
    @AppStorage(CloudSyncService.enabledKey) private var iCloudSyncEnabled =
        false
    @State private var iCloudAvailable = false
    /// Device-local, read by `RenewalReminders`.
    @AppStorage(RenewalReminders.enabledKey) private var remindersEnabled =
        false
    @AppStorage(RenewalReminders.leadDaysKey) private var reminderLeadDays = 1
    @State private var notificationsDenied = false

    init(
        settingsStore: SettingsStore,
        store: AppStore,
        coordinator: AppCoordinator
    ) {
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
                    KasagiHeader()
                    section("Budget") {
                        SettingsCard(topInset: 8, bottomInset: 16) {
                            BudgetEditor(
                                settingsStore: vm.settingsStore,
                                store: vm.store
                            )
                        }
                    }
                    section("Money & Display") {
                        moneyAndDisplayPreferences(vm: vm)
                    }
                    section("Organize") { filtersPreferences(vm: vm) }
                    section("Appearance") { appearancePreferences(vm: vm) }
                    if FeatureFlags.renewals {
                        section("Notifications") {
                            notificationsSection(vm: vm)
                        }
                    }
                    section("Privacy & Data") { aboutSection(vm: vm) }
                    section("Danger Zone") { dangerZone(vm: vm) }
                    VStack(spacing: 8) {
                        HStack {
                            Text("Made with")
                            Image(systemName: "suit.heart.fill")
                                .foregroundStyle(Color.shu)
                            Text("by")
                            Link(
                                "@tony_linguica",
                                destination: URL(string: "x.com/tony_linguica")!
                            )
                        }
                        .typography(.titleSmall)
                        .foregroundStyle(Color.inkSecondary)
                        HStack {
                            Text("version: 0.0.1")
                                .typography(.bodySmall)
                                .foregroundStyle(Color.inkSecondary)
                        }
                    }
                }
                .padding(.horizontal, 8)
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
                    switch ProcessInfo.processInfo.environment[
                        "DEBUG_OPEN_SETTINGS_PAGE"
                    ] {
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
                        Image(systemName: "xmark").foregroundStyle(Color.ink)
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
            Text(
                "This permanently deletes all \(viewModel.expensesCount) expenses and their logos\(iCloudSyncEnabled ? " from all your devices" : ""). Categories, payment methods, lists, budget and appearance stay as configured. This can't be undone."
            )
        }
        .alert("Reset App Completely?", isPresented: $showResetAppAlert) {
            Button("Reset", role: .destructive) {
                viewModel.resetAppCompletely()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This permanently deletes every expense, category, payment method, list and preference, then restarts onboarding as if freshly installed. This can't be undone."
            )
        }
    }

    /// Section title + content, spaced per the app's settings grouping style.
    private func section(
        _ title: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(title, markerVariant: .default)
            content()
        }
    }

    @ViewBuilder
    private func appearancePreferences(vm: SettingsViewModel) -> some View {
        SettingsCard(topInset: 16, bottomInset: 8) {
            AppearanceSelector(selection: vm.themeModeBinding())
            Rule().padding(.vertical, 8)
            SettingsNavigationRow(
                icon: "calendar",
                title: "Calendar Style",
                actionText: vm.calendarStyleName
            ) { vm.showCalendarStyle = true }
        }
    }

    @ViewBuilder
    private func notificationsSection(vm: SettingsViewModel) -> some View {
        SettingsCard(
            topInset: 16,
            bottomInset: remindersEnabled || notificationsDenied ? 8 : 16
        ) {
            SettingsToggleRow(
                icon: "bell.badge",
                title: "Renewal reminders",
                description: notificationsDenied
                    ? "Allow notifications in Settings"
                    : "A heads-up before subscriptions renew",
                isOn: $remindersEnabled
            ) { on in
                Task {
                    let allowed = await vm.store.reminders?.setEnabled(on) ?? true
                    guard on else { return }
                    notificationsDenied = !allowed
                    if !allowed { remindersEnabled = false }
                }
            }

            if notificationsDenied {
                Rule().padding(.vertical, 8)
                SettingsNavigationRow(
                    icon: "gearshape",
                    title: "Open Settings",
                    actionText: "Notifications"
                ) {
                    guard let url = URL(
                        string: UIApplication.openNotificationSettingsURLString
                    ) else { return }
                    UIApplication.shared.open(url)
                }
            }

            if remindersEnabled {
                Rule().padding(.vertical, 8)
                HStack(spacing: 8) {
                    SettingsRowLabel(icon: "clock", title: "Remind me")
                    Picker("Remind me", selection: $reminderLeadDays) {
                        ForEach(RenewalReminders.leadDayOptions, id: \.self) {
                            days in
                            Text(
                                days == 0
                                    ? "Same day"
                                    : days == 1
                                        ? "1 day before" : "\(days) days before"
                            )
                            .tag(days)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.ink)
                }
                .settingsRowFrame()
                .onChange(of: reminderLeadDays) { _, _ in
                    vm.store.reminders?.reschedule()
                }
            }
        }
        .task {
            notificationsDenied =
                await vm.store.reminders?.authorizationStatus() == .denied
        }
    }

    @ViewBuilder
    private func aboutSection(vm: SettingsViewModel) -> some View {
        SettingsCard(topInset: 16, bottomInset: 8) {
            SettingsToggleRow(
                icon: "icloud",
                title: "Sync with iCloud",
                description: iCloudAvailable
                    ? "Keep expenses and settings on all your devices"
                    : "Sign in to iCloud in the Settings app",
                isOn: $iCloudSyncEnabled
            ) { enabled in
                vm.store.sync?.setEnabled(enabled)
            }
            .disabled(!iCloudAvailable)

            Rule().padding(.vertical, 8)
            SettingsNavigationRow(
                icon: "hand.raised",
                title: "Privacy"
            ) { vm.showPrivacy = true }

            Rule().padding(.vertical, 8)
            SettingsNavigationRow(
                icon: "internaldrive",
                title: "How My Data Is Saved"
            ) { vm.showDataInfo = true }
        }
        .task {
            let status = try? await CKContainer(
                identifier: CloudSyncService.containerID
            ).accountStatus()
            iCloudAvailable = status == .available
        }
    }

    @ViewBuilder
    private func moneyAndDisplayPreferences(vm: SettingsViewModel) -> some View {
        SettingsCard(topInset: 8, bottomInset: 16) {
            SettingsNavigationRow(
                icon: "banknote.fill",
                title: "Main Currency",
                actionText: vm.currencyCode
            ) { vm.showCurrencyPicker = true }

            Rule().padding(.vertical, 8)
            SettingsToggleRow(
                icon: "0.circle.fill",
                title: "Rounding",
                description: "Display amounts without decimals",
                isOn: vm.roundAmountsBinding()
            )

            Rule().padding(.vertical, 8)
            SettingsToggleRow(
                icon: "k.circle.fill",
                title: "Abbreviate Large Numbers",
                description: "Use compact format like 74.5k",
                isOn: vm.abbreviateLargeNumbersBinding()
            )
        }
    }

    @ViewBuilder
    private func filtersPreferences(vm: SettingsViewModel) -> some View {
        SettingsCard(topInset: 8, bottomInset: 8) {
            SettingsNavigationRow(
                icon: "square.grid.2x2",
                title: "Categories",
                actionText: "\(vm.categoriesCount)"
            ) { vm.showCategories = true }

            Rule().padding(.vertical, 8)
            SettingsNavigationRow(
                icon: "creditcard",
                title: "Payment Methods",
                actionText: "\(vm.paymentMethodsCount)"
            ) { vm.showPaymentMethods = true }

            Rule().padding(.vertical, 8)
            SettingsNavigationRow(
                icon: "list.dash",
                title: "Lists",
                actionText: "\(vm.listsCount)"
            ) { vm.showLists = true }
        }
    }

    @ViewBuilder
    private func dangerZone(vm: SettingsViewModel) -> some View {
        SettingsCard {
            AppButton(
                title: "Delete All Data",
                icon: "trash",
                style: .destructive,
                appearance: .outline,
                size: .medium,
                expands: true,
                action: { showDeleteDataAlert = true }
            )

            Rule().padding(.vertical, 8)
            AppButton(
                title: "Reset App Completely",
                icon: "arrow.counterclockwise",
                style: .destructive,
                appearance: .outline,
                size: .medium,
                expands: true,
                action: { showResetAppAlert = true }
            )
        }
    }
}

#Preview {
    SettingsViewPreviewHost()
}
