import SwiftUI

/// Hold-to-speak expense entry: parsed items stack at the top as they're
/// spoken (glass cards, logo + name + amount + category, matching the batch
/// and form styling); a floating glass box with a big purple hold-to-speak
/// button sits at the bottom of the sheet.
struct VoiceAddSheet: View {
    @State private var viewModel: VoiceAddViewModel
    @State private var keypadItemID: UUID?
    @State private var currencyCode: String = ""
    @Environment(\.dismiss) private var dismiss

    private let onSaved: () -> Void

    init(
        date: Date,
        store: AppStore,
        settingsStore: SettingsStore,
        onSaved: @escaping () -> Void = {}
    ) {
        _viewModel = State(
            initialValue: VoiceAddViewModel(
                date: date,
                store: store,
                settingsStore: settingsStore
            )
        )
        self.onSaved = onSaved
    }

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if vm.items.isEmpty {
                        emptyState
                    } else {
                        ForEach($vm.items) { $item in
                            itemRow($item)
                        }

                        totalRow(vm: vm)

                        AppButton(
                            title: "Add Item",
                            icon: "plus",
                            style: .secondary,
                            appearance: .outline,
                            expands: true
                        ) {
                            withAnimation(.spring(duration: 0.35)) {
                                vm.addBlankItem()
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .appBackground()
            .navigationTitle("Speak an Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await vm.cancelRecording() }
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.saveAll()
                        dismiss()
                        onSaved()
                    } label: {
                        Text("Add \(vm.saveCount)")
                            .typography(.labelLarge)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(Color.green.gradient)
                    .disabled(!vm.canSave)
                }
            }
            .safeAreaInset(edge: .bottom) {
                floatingControls(vm: vm)
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            if currencyCode.isEmpty {
                currencyCode = viewModel.settingsStore.settings.currencyCode
            }
        }
        .sheet(isPresented: keypadBinding) {
            if let index = keypadItemIndex {
                NumKeyPadSheet(
                    amount: $viewModel.items[index].amount,
                    currencyCode: $currencyCode,
                    typingStyle: .decimal
                ) {
                    keypadItemID = nil
                }
                .environment(viewModel.settingsStore)
                .presentationDetents([.height(560)])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "waveform.badge.mic")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.secondary)
            Text("Hold the button and speak")
                .typography(.titleMedium)
                .foregroundStyle(.primary)
            Text("Try \"50 dollars on Safeway\" or\n\"yesterday I spent 20 on groceries\".")
                .typography(.bodyMedium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Item rows (top)

    private func itemRow(_ item: Binding<ParsedExpense>) -> some View {
        GlassSection {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    LogoCircle(
                        size: 44,
                        customization: viewModel.customization(for: item.wrappedValue),
                        logoName: SubscriptionTemplate.logoName(for: item.wrappedValue.name),
                        name: item.wrappedValue.name,
                        preferInitials: true
                    )

                    TextField("Name", text: item.name)
                        .typography(.titleMedium)
                        .foregroundStyle(.primary)
                        .submitLabel(.done)

                    AppButton(
                        icon: "trash",
                        accessibilityTitle: "Remove",
                        style: .destructive,
                        appearance: .ghost,
                        size: .small
                    ) {
                        withAnimation(.spring(duration: 0.35)) {
                            viewModel.items.removeAll { $0.id == item.wrappedValue.id }
                        }
                    }
                }

                Divider()

                HStack {
                    Button {
                        keypadItemID = item.wrappedValue.id
                    } label: {
                        Text(amountLabel(for: item.wrappedValue))
                            .typography(.titleMedium)
                            .foregroundStyle(
                                item.wrappedValue.amount > 0 ? .green : .secondary
                            )
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(viewModel.dateLabel(for: item.wrappedValue))
                        .typography(.labelMedium)
                        .foregroundStyle(.secondary)

                    categoryChipMenu(item)
                }
            }
        }
    }

    /// Category selector: menu whose label is the form's selected-chip look —
    /// category color fill + contrasting text.
    private func categoryChipMenu(_ item: Binding<ParsedExpense>) -> some View {
        let color = categoryColor(for: item.wrappedValue.category)
        return Menu {
            ForEach(viewModel.categories) { category in
                Button(category.name) { item.wrappedValue.category = category.name }
            }
        } label: {
            Text(item.wrappedValue.category)
                .typography(.bodyMedium.weight(.semibold))
                .foregroundStyle(color.contrastingForeground)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(color))
        }
    }

    private func categoryColor(for name: String) -> Color {
        guard let category = viewModel.categories.first(where: { $0.name == name }) else {
            return Color.gray
        }
        return Color(hex: category.colorHex)
    }

    private func totalRow(vm: VoiceAddViewModel) -> some View {
        HStack {
            Text("\(vm.saveCount) item\(vm.saveCount == 1 ? "" : "s")")
            Spacer()
            Text(
                MoneyFormatter.format(
                    vm.totalPrice,
                    settings: vm.settingsStore.settings
                )
            )
        }
        .typography(.labelMedium)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)
    }

    private func amountLabel(for item: ParsedExpense) -> String {
        guard item.amount > 0 else { return "Amount" }
        let symbol = MoneyFormatter.symbol(for: currencyCode)
        return "\(symbol)\(item.amount.asPeriodCurrency)"
    }

    private var keypadItemIndex: Int? {
        guard let id = keypadItemID else { return nil }
        return viewModel.items.firstIndex { $0.id == id }
    }

    private var keypadBinding: Binding<Bool> {
        Binding(
            get: { keypadItemID != nil },
            set: { if !$0 { keypadItemID = nil } }
        )
    }

    // MARK: - Floating hold-to-speak (bottom)

    @ViewBuilder
    private func floatingControls(vm: VoiceAddViewModel) -> some View {
        GlassSection {
            VStack(spacing: 10) {
                if vm.isRecording && !vm.transcript.isEmpty {
                    Text(vm.transcript)
                        .typography(.bodyMedium)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                if let message = vm.errorMessage {
                    VStack(spacing: 6) {
                        Text(message)
                            .typography(.bodySmall)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                        if vm.micDenied {
                            Button("Open Settings") {
                                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                                UIApplication.shared.open(url)
                            }
                            .typography(.labelLarge)
                        }
                    }
                }

                holdButton(vm: vm)
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 8)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .animation(.spring(duration: 0.3), value: vm.isRecording)
        .animation(.spring(duration: 0.3), value: vm.transcript.isEmpty)
    }

    @ViewBuilder
    private func holdButton(vm: VoiceAddViewModel) -> some View {
        VStack(spacing: 8) {
            if vm.isProcessing {
                ProgressView()
                    .tint(.white)
                Text("Adding…")
            } else {
                Image(systemName: vm.isRecording ? "waveform" : "mic.fill")
                    .font(.system(size: 32, weight: .medium))
                    .symbolEffect(.variableColor.iterative, isActive: vm.isRecording)
                Text(vm.isRecording ? "Release to add" : "Hold & speak")
            }
        }
        .typography(.titleMedium)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 128)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill((vm.isRecording ? Color.red : Color.purple).gradient)
        )
        .scaleEffect(vm.isRecording ? 1.02 : 1)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in vm.beginHold() }
                .onEnded { _ in vm.endHold() }
        )
        .allowsHitTesting(!vm.isProcessing)
    }
}
