import SwiftUI
import UIKit

/// One-screen add-expense flow: opens straight on a blank form, with the
/// popular-services catalog available as an optional fill-in rather than a
/// mandatory first step.
struct SimplifiedAddExpenseView: View {
    @State private var viewModel: SimplifiedAddExpenseViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var nameFocused: Bool
    @State private var scrollPosition = ScrollPosition()

    init(
        date: Date,
        store: AppStore,
        settingsStore: SettingsStore,
        onCommit: @escaping (Expense) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: SimplifiedAddExpenseViewModel(
            mode: .createBlank(name: "", date: date),
            store: store,
            settingsStore: settingsStore,
            onCommit: onCommit
        ))
    }

    /// Edit variant: same screen, minus the popular-services fill and the
    /// add-another button, plus delete.
    init(
        expense: Expense,
        store: AppStore,
        settingsStore: SettingsStore,
        onCommit: @escaping (Expense) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: SimplifiedAddExpenseViewModel(
            mode: .edit(expense),
            store: store,
            settingsStore: settingsStore,
            onCommit: onCommit
        ))
    }

    var body: some View {
        @Bindable var vm = viewModel
        @Bindable var form = viewModel.form

        NavigationStack {
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [vm.backgroundBase, vm.backgroundShade],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        LogoHeaderSection(
                            customization: form.customization,
                            logoName: vm.logoName,
                            name: bindingForName(),
                            nameError: form.nameError,
                            isLocked: vm.isLogoLocked,
                            accent: vm.accent,
                            onTapLogo: { vm.openLogoSheet() },
                            nameFieldFocus: $nameFocused
                        )
                        .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 6) {
                            LabeledSection("Amount", titleColor: vm.accent.opacity(0.85)) {
                                AmountField(
                                    amount: form.price,
                                    currencyCode: form.currencyCode,
                                    hasError: form.priceError != nil,
                                    onTap: { form.showKeypad = true }
                                )
                            }

                            if let priceError = form.priceError {
                                Text(priceError)
                                    .typography(.bodySmall)
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 8)
                            }
                        }

                        if !vm.isEditMode {
                            LabeledSection(
                                "Fill from popular services",
                                titleColor: vm.accent.opacity(0.85)
                            ) {
                                PopularServicesRow(
                                    selectedName: vm.selectedTemplate?.name,
                                    accent: vm.accent,
                                    onTap: { vm.showCatalog = true },
                                    onClear: { vm.clearTemplate() }
                                )
                            }
                        }

                        LabeledSection("Categorization", titleColor: vm.accent.opacity(0.85)) {
                            CategorizationSection(
                                type: $form.type,
                                category: $form.category,
                                list: $form.list,
                                paymentMethod: $form.paymentMethod,
                                categoryOptions: form.categoryOptions,
                                listOptions: form.listOptions,
                                paymentOptions: form.paymentOptions,
                                tint: vm.accent
                            )
                        }

                        LabeledSection("More details", titleColor: vm.accent.opacity(0.85)) {
                            MoreDetailsSection(
                                startDate: $form.startDate,
                                endDate: $form.endDate,
                                billingCycle: $form.billingCycle,
                                notes: $form.notes,
                                tint: vm.accent
                            )
                        }

                        Spacer(minLength: 100)
                    }
                    .padding()
                }
                .scrollPosition($scrollPosition)
                .scrollDismissesKeyboard(.interactively)

                if !form.isNativeKeyboardVisible {
                    AppButton(
                        title: vm.isEditMode ? "Save" : "Create and add another",
                        icon: vm.isEditMode ? "checkmark" : "plus.square.on.square",
                        style: .neutral,
                        appearance: .solid,
                        size: .large,
                        expands: true,
                        action: {
                            if vm.isEditMode {
                                if vm.add() { dismiss() } else { revealErrors() }
                            } else if vm.addAnother() {
                                nameFocused = true
                            } else {
                                revealErrors()
                            }
                        }
                    )
                    .padding(.horizontal, 16)
                }
            }
            .toolbar { toolbar }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $vm.showCatalog) {
                SubscriptionCatalogView(
                    templates: vm.filteredTemplates,
                    searchText: $vm.searchText,
                    showEmptyCTA: vm.showEmptyCTA,
                    onSelect: { vm.apply($0) },
                    onCreateBlank: { vm.applyBlank(named: $0) }
                )
            }
        }
        .tint(vm.accent)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
            form.keyboardAppeared()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { _ in
            form.keyboardDismissed()
        }
        .onAppear {
            form.onAppear()
            // Editing opens on an already-named expense — don't shove the
            // keyboard over the form the user came to review.
            if form.name.trimmingCharacters(in: .whitespaces).isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    nameFocused = true
                }
            }
        }
        .alert("Delete Expense", isPresented: $form.showDeleteAlert) {
            Button("Delete", role: .destructive) {
                form.deleteOriginal()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(form.deleteAlertMessage)
        }
        .sheet(isPresented: $form.showKeypad) {
            NumKeyPadSheet(
                amount: $form.price,
                currencyCode: $form.currencyCode,
                typingStyle: .decimal
            ) {
                form.showKeypad = false
            }
            .environment(form.settingsStore)
            .presentationDetents([.height(560)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $form.showLogoSheet) {
            LogoSheet(
                customization: form.customizationBinding(),
                name: form.name
            ) {
                form.showLogoSheet = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") { dismiss() }
        }
        // Editing commits from the floating button, so the trailing slot is
        // free for delete.
        ToolbarItem(placement: .topBarTrailing) {
            if viewModel.isEditMode {
                Button {
                    viewModel.form.showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.glassProminent)
                .tint(.red)
            } else {
                Button("Add") {
                    if viewModel.add() { dismiss() } else { revealErrors() }
                }
                .buttonStyle(.glassProminent)
            }
        }
    }

    /// Name and amount errors render at the top of the form — scroll back up
    /// so a failed save isn't silent when the user is down by the buttons.
    private func revealErrors() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            scrollPosition.scrollTo(edge: .top)
        }
    }

    /// Typing over a template's name drops the template — the brand logo no
    /// longer matches what the user is entering.
    private func bindingForName() -> Binding<String> {
        Binding(
            get: { viewModel.form.name },
            set: { newValue in
                if let template = viewModel.selectedTemplate, newValue != template.name {
                    viewModel.detachTemplate()
                }
                viewModel.form.name = newValue
                viewModel.form.clearNameErrorIfFixed()
            }
        )
    }
}

#Preview {
    SimplifiedAddExpensePreviewHost()
}
