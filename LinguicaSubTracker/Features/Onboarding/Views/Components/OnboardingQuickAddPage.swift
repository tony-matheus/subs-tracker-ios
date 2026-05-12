import SwiftUI

/// Final onboarding step: a super-simplified form to add any number of
/// subscriptions (name, amount, start date). Commits through the existing
/// `AppStore.add` pipeline on finish.
struct OnboardingQuickAddPage: View {
    @Bindable var viewModel: OnboardingViewModel
    let onFinish: () -> Void

    @State private var keypadDraftID: UUID?
    @State private var currencyCode: String = ""

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Add your subscriptions")
                    .typography(.displaySmall)
                    .foregroundStyle(.primary)
                Text("Just the basics — you can fine-tune them later.")
                    .typography(.bodyLarge)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 16)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach($viewModel.drafts) { $draft in
                        draftRow($draft)
                    }

                    AppButton(
                        title: "Add another",
                        icon: "plus",
                        style: .secondary,
                        appearance: .outline,
                        expands: true
                    ) {
                        withAnimation(.spring(duration: 0.35)) {
                            viewModel.addDraft()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }

            footer
        }
        .onAppear {
            if currencyCode.isEmpty {
                currencyCode = viewModel.settingsStore.settings.currencyCode
            }
        }
        .sheet(isPresented: keypadBinding) {
            if let index = keypadDraftIndex {
                NumKeyPadSheet(
                    amount: $viewModel.drafts[index].price,
                    currencyCode: $currencyCode,
                    typingStyle: .decimal
                ) {
                    keypadDraftID = nil
                }
                .environment(viewModel.settingsStore)
                .presentationDetents([.height(560)])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Rows

    private func draftRow(_ draft: Binding<OnboardingDraft>) -> some View {
        GlassSection {
            VStack(spacing: 12) {
                HStack {
                    TextField("Netflix, Spotify…", text: draft.name)
                        .typography(.titleMedium)
                        .foregroundStyle(.primary)
                        .submitLabel(.done)

                    if viewModel.drafts.count > 1 {
                        AppButton(
                            icon: "trash",
                            accessibilityTitle: "Remove",
                            style: .destructive,
                            appearance: .ghost,
                            size: .small
                        ) {
                            withAnimation(.spring(duration: 0.35)) {
                                viewModel.removeDraft(id: draft.wrappedValue.id)
                            }
                        }
                    }
                }

                Divider()

                HStack {
                    Button {
                        keypadDraftID = draft.wrappedValue.id
                    } label: {
                        Text(amountLabel(for: draft.wrappedValue))
                            .typography(.titleMedium)
                            .foregroundStyle(
                                draft.wrappedValue.price > 0 ? .green : .secondary
                            )
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    DatePicker(
                        "Starts",
                        selection: draft.startDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 8) {
            AppButton(
                title: footerTitle,
                style: .primary,
                appearance: .solid,
                size: .large,
                expands: true
            ) {
                viewModel.commit()
                onFinish()
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    // MARK: - Helpers

    private var footerTitle: String {
        let count = viewModel.validDrafts.count
        switch count {
        case 0: return "Start without adding"
        case 1: return "Add 1 subscription & start"
        default: return "Add \(count) subscriptions & start"
        }
    }

    private func amountLabel(for draft: OnboardingDraft) -> String {
        guard draft.price > 0 else { return "Amount" }
        let symbol = MoneyFormatter.symbol(for: currencyCode)
        return "\(symbol)\(draft.price.asPeriodCurrency)"
    }

    private var keypadDraftIndex: Int? {
        guard let id = keypadDraftID else { return nil }
        return viewModel.drafts.firstIndex { $0.id == id }
    }

    private var keypadBinding: Binding<Bool> {
        Binding(
            get: { keypadDraftID != nil },
            set: { if !$0 { keypadDraftID = nil } }
        )
    }
}
