import SwiftUI
import UIKit

struct SubscriptionFormView: View {
    @State private var viewModel: SubscriptionFormViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var nameFocused: Bool

    init(
        mode: SubscriptionFormMode,
        store: AppStore,
        settingsStore: SettingsStore,
        onCommit: @escaping (Subscription) -> Void
    ) {
        _viewModel = State(initialValue: SubscriptionFormViewModel(
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
                        SubscriptionLogoCircle(
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
                        GlassSection {
                            FormRow(label: "Name", labelColor: vm.themeAccent) {
                                TextField("Your subscription name", text: $vm.name)
                                    .multilineTextAlignment(.trailing)
                                    .typography(.bodyMedium)
                                    .focused($nameFocused)
                                    .onChange(of: vm.name) { _, _ in vm.clearNameErrorIfFixed() }
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture { nameFocused = true }

                            if let err = vm.nameError {
                                Text(err)
                                    .typography(.bodySmall)
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .padding(.top, 4)
                            }

                            Divider()

                            FormRow(label: "Payment Schedule", labelColor: vm.themeAccent) {
                                AppPicker(
                                    title: "",
                                    selection: $vm.schedule,
                                    options: [
                                        (value: .monthly, label: "Monthly"),
                                        (value: .yearly, label: "Yearly"),
                                    ],
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
                                        Button("Set end date") {
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
                        }

                        GlassSection {
                            VStack(alignment: .leading, spacing: 6) {
                                Button {
                                    vm.showKeypad = true
                                } label: {
                                    FormRow(label: "Amount", labelColor: vm.themeAccent) {
                                        Text(vm.price, format: .currency(code: vm.currencyCode))
                                            .typography(.headlineSmall.weight(.regular))
                                            .foregroundStyle(vm.priceError != nil ? .red : .primary)
                                    }
                                }
                                .buttonStyle(.plain)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(vm.priceError != nil ? Color.red : Color.clear, lineWidth: 1)
                                        .padding(-6)
                                )
                                if let err = vm.priceError {
                                    Text(err)
                                        .typography(.bodySmall)
                                        .foregroundStyle(.red)
                                }
                            }
                            .onChange(of: vm.price) { _, _ in vm.clearPriceErrorIfFixed() }
                        }

                        GlassSection {
                            FormRow(
                                label: "Category",
                                icon: "tag.fill",
                                iconColor: vm.themeAccent,
                                labelColor: vm.themeAccent
                            ) {
                                AppPicker(
                                    title: "",
                                    selection: $vm.category,
                                    options: vm.categoryOptions,
                                    tint: vm.themeAccent
                                )
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
                        }

                        GlassSection {
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
                            Text("Close")
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
            SubscriptionLogoSheet(
                customization: vm.customizationBinding(),
                subscriptionName: vm.name
            ) {
                vm.closeLogoSheet()
            }
            .presentationDetents([.large, .fraction(0.62)])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.disabled)
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Subscription", isPresented: $vm.showDeleteAlert) {
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
    SubscriptionFormViewPreviewHost(variant: .create)
}

#Preview("Edit") {
    SubscriptionFormViewPreviewHost(variant: .edit)
}
