import SwiftUI
import UIKit

struct ExpenseFormView: View {
    @State private var viewModel: ExpenseFormViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var nameFocused: Bool

    init(
        mode: ExpenseFormMode,
        store: AppStore,
        settingsStore: SettingsStore,
        onCommit: @escaping (Expense) -> Void
    ) {
        _viewModel = State(initialValue: ExpenseFormViewModel(
            mode: mode,
            store: store,
            settingsStore: settingsStore,
            onCommit: onCommit
        ))
    }

    var body: some View {
        if viewModel.isEditMode {
            NavigationStack {
                formContent
                    .toolbar { editToolbar }
                    .toolbarBackground(.hidden, for: .navigationBar)
                    .appBackground()
            }
            .tint(viewModel.themeAccent)
        } else {
            formContent
                .appBackground()
        }
    }

    @ToolbarContentBuilder
    private var editToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
        }
        ToolbarItem(placement: .principal) {
            Text(viewModel.navigationTitle)
                .typography(.titleMedium.weight(.semibold))
                .foregroundStyle(viewModel.themeAccent)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.showDeleteAlert = true
            } label: {
                Image(systemName: "trash")
            }.buttonStyle(.glassProminent).tint(.red)
        }
    }

    // MARK: - Hero fields

    /// Large borderless title-style name field under the logo.
    private func nameField(vm: ExpenseFormViewModel) -> some View {
        @Bindable var vm = vm
        return VStack(spacing: 4) {
            TextField("Expense name", text: $vm.name)
                .multilineTextAlignment(.center)
                .typography(.headlineMedium)
                .foregroundStyle(vm.themeAccent)
                .focused($nameFocused)
                .submitLabel(.done)
                .onChange(of: vm.name) { _, _ in vm.clearNameErrorIfFixed() }

            if let err = vm.nameError {
                Text(err)
                    .typography(.bodySmall)
                    .foregroundStyle(.red)
            }
        }
    }

    /// Visual centerpiece — big tap target that opens the keypad.
    private func amountButton(vm: ExpenseFormViewModel) -> some View {
        VStack(spacing: 6) {
            Button {
                vm.showKeypad = true
            } label: {
                VStack(spacing: 4) {
                    Text("Amount")
                        .typography(.labelMedium)
                        .foregroundStyle(vm.themeAccent.opacity(0.85))
                    Text(vm.price, format: .currency(code: vm.currencyCode))
                        .typography(.displaySmall)
                        .foregroundStyle(vm.priceError != nil ? Color.red : Color.primary)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.price)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            }
            .buttonStyle(.plain)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(vm.priceError != nil ? Color.red : Color.clear, lineWidth: 1)
            )

            if let err = vm.priceError {
                Text(err)
                    .typography(.bodySmall)
                    .foregroundStyle(.red)
            }
        }
        .onChange(of: vm.price) { _, _ in vm.clearPriceErrorIfFixed() }
    }

    /// Horizontal color-chip row driven by the user's categories.
    private func categoryChips(vm: ExpenseFormViewModel) -> some View {
        GlassSection {
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .typography(.labelMedium)
                    .foregroundStyle(vm.themeAccent.opacity(0.85))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(vm.settingsStore.settings.categories) { category in
                            categoryChip(category, vm: vm)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func categoryChip(_ category: AppCategory, vm: ExpenseFormViewModel) -> some View {
        let color = Color(hex: category.colorHex)
        let isSelected = vm.category == category.name

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                vm.category = category.name
            }
        } label: {
            Text(category.name)
                .typography(.bodyMedium.weight(.semibold))
                .foregroundStyle(isSelected ? color.contrastingForeground : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(isSelected ? color : color.opacity(0.14))
                )
                .overlay(
                    Capsule().stroke(
                        isSelected ? Color.clear : color.opacity(0.55),
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Secondary fields

    private func moreDetailsSection(vm: ExpenseFormViewModel) -> some View {
        @Bindable var vm = vm
        return GlassSection {
            HStack {
                Text("More details")
                    .typography(.titleMedium)
                    .foregroundStyle(vm.themeAccent)
                Spacer()
            }

            VStack(spacing: 0) {
                    Divider().padding(.vertical, 8)

                    FormRow(label: "Type", labelColor: vm.themeAccent) {
                        AppPicker(
                            title: "",
                            selection: $vm.type,
                            options: ExpenseType.allCases.map {
                                (value: $0, label: $0.displayName)
                            },
                            tint: vm.themeAccent
                        )
                    }

                    Divider()

                    FormRow(label: "Payment Schedule", labelColor: vm.themeAccent) {
                        AppPicker(
                            title: "",
                            selection: $vm.billingCycle,
                            options: BillingCycle.allCases.map {
                                (value: $0, label: $0.displayName)
                            },
                            tint: vm.themeAccent
                        )
                    }

                    Divider()

                    FormRow(label: "Start Date", labelColor: vm.themeAccent) {
                        DatePicker(
                            "",
                            selection: $vm.startDate,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .typography(.bodyMedium)
                        .tint(vm.themeAccent)
                    }

                    Divider()

                    FormRow(label: "End Date", labelColor: vm.themeAccent) {
                        HStack(spacing: 8) {
                            if let end = vm.endDate {
                                DatePicker(
                                    "",
                                    selection: Binding(
                                        get: { end },
                                        set: { vm.endDate = $0 }
                                    ),
                                    in: vm.startDate...,
                                    displayedComponents: .date
                                )
                                .labelsHidden()
                                .typography(.bodyMedium)
                                .tint(vm.themeAccent)

                                Button {
                                    vm.endDate = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button("Set End Date") {
                                    vm.endDate = Calendar.current.date(
                                        byAdding: .month,
                                        value: 1,
                                        to: vm.startDate
                                    ) ?? vm.startDate
                                }
                                .typography(.bodyMedium)
                                .foregroundStyle(vm.themeAccent)
                            }
                        }
                    }

                    Divider()

                    FormRow(
                        label: "Pay with",
                        icon: "wallet.bifold.fill",
                        iconColor: vm.themeAccent,
                        labelColor: vm.themeAccent
                    ) {
                        AppPicker(
                            title: "",
                            selection: $vm.paymentMethod,
                            options: vm.paymentOptions,
                            tint: vm.themeAccent
                        )
                    }

                    Divider()

                    FormRow(
                        label: "List",
                        icon: "list.dash",
                        iconColor: vm.themeAccent,
                        labelColor: vm.themeAccent
                    ) {
                        AppPicker(
                            title: "",
                            selection: $vm.list,
                            options: vm.listOptions,
                            tint: vm.themeAccent
                        )
                    }

                    Divider().padding(.bottom, 8)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .typography(.titleMedium)
                            .foregroundStyle(vm.themeAccent)

                        TextEditor(text: $vm.notes)
                            .frame(height: 100)
                            .scrollContentBackground(.hidden)
                            .typography(.bodyMedium)
                    }
            }
        }
    }

    private var formContent: some View {
        @Bindable var vm = viewModel

        return ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [vm.themePrimary, vm.themePrimary.darker(by: 0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                            vm.openLogoSheet()
                        }
                    } label: {
                        LogoCircle(
                            size: vm.isLogoExpanded ? 160 : 120,
                            customization: vm.customization,
                            logoName: vm.logoName,
                            name: vm.name
                        )
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.78),
                            value: vm.isLogoExpanded
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, vm.isLogoExpanded ? 60 : 16)

                    Group {
                        nameField(vm: vm)

                        amountButton(vm: vm)

                        categoryChips(vm: vm)

                        moreDetailsSection(vm: vm)

                        Spacer(minLength: 100)
                    }
                    .opacity(vm.isLogoExpanded ? 0 : 1)
                    .allowsHitTesting(!vm.isLogoExpanded)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)

            Group {
                if vm.isLogoExpanded {
                    EmptyView()
                } else if vm.isNativeKeyboardVisible {
                    HStack {
                        Spacer()
                        Button {
                            vm.dismissNativeKeyboard()
                        } label: {
                            Text("Done")
                                .typography(.bodyMedium.weight(.semibold))
                                .foregroundStyle(.foreground)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                        .glassEffect(.regular.interactive())
                        .padding()
                    }
                } else {
                    AppButton(
                        title: vm.primaryButtonTitle,
                        icon: "plus",
                        style: .neutral,
                        appearance: .solid,
                        size: .large,
                        expands: true,
                        action: {
                            if vm.commit() != nil { dismiss() }
                        }
                    )
                    .padding(.horizontal, 16)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
            vm.keyboardAppeared()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { _ in
            vm.keyboardDismissed()
        }
        .onAppear {
            vm.onAppear()
            if vm.name.trimmingCharacters(in: .whitespaces).isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    nameFocused = true
                }
            }
        }
        .sheet(isPresented: $vm.showKeypad) {
            NumKeyPadSheet(amount: $vm.price, currencyCode: $vm.currencyCode, typingStyle: .decimal) {
                vm.showKeypad = false
            }
            .environment(vm.settingsStore)
            .presentationDetents([.height(560)])
            .presentationDragIndicator(.visible)
        }
        .sheet(
            isPresented: $vm.showLogoSheet,
            onDismiss: {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                    vm.isLogoExpanded = false
                }
            }
        ) {
            LogoSheet(
                customization: vm.customizationBinding(),
                name: vm.name
            ) {
                vm.closeLogoSheet()
            }
            .presentationDetents([.large, .fraction(0.62)])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.disabled)
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Expense", isPresented: $vm.showDeleteAlert) {
            Button("Delete", role: .destructive) {
                vm.deleteOriginal()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(vm.deleteAlertMessage)
        }
    }
}

#Preview("Create") {
    ExpenseFormViewPreviewHost(variant: .create)
}

#Preview("Edit") {
    ExpenseFormViewPreviewHost(variant: .edit)
}
