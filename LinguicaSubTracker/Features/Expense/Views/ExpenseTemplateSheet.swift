import SwiftUI

/// Entry point for adding an expense: a bento hub of add methods with a
/// hold-to-speak bar at the bottom. Holding the bar records speech and the
/// page morphs into the voice review list (rows of parsed expenses); if a
/// recording yields nothing, the hub returns to the bento options.
struct ExpenseTemplateSheet: View {
    @State private var viewModel: ExpenseTemplateSheetViewModel
    @State private var voiceViewModel: VoiceAddViewModel
    @State private var showReceiptScan: Bool = false
    @State private var showBatchAdd: Bool = false
    @State private var keypadItemID: UUID?
    @State private var currencyCode: String = ""
    @Environment(\.dismiss) private var dismiss

    let store: AppStore
    let settingsStore: SettingsStore

    init(date: Date, store: AppStore, settingsStore: SettingsStore) {
        self.store = store
        self.settingsStore = settingsStore
        _viewModel = State(
            initialValue: ExpenseTemplateSheetViewModel(date: date)
        )
        _voiceViewModel = State(
            initialValue: VoiceAddViewModel(
                date: date,
                store: store,
                settingsStore: settingsStore
            )
        )
    }

    /// Recording, processing, or reviewing spoken items → voice layout.
    private var isVoiceMode: Bool {
        voiceViewModel.isRecording
            || voiceViewModel.isProcessing
            || !voiceViewModel.items.isEmpty
    }

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            ScrollView {
                Group {
                    if isVoiceMode {
                        voiceReviewList
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        bentoGrid(vm: vm)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isVoiceMode)
            .appBackground()
            .navigationTitle(isVoiceMode ? "Speak an Expense" : "Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await voiceViewModel.cancelRecording() }
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                if isVoiceMode {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            voiceViewModel.saveAll()
                            dismiss()
                        } label: {
                            Text("Add \(voiceViewModel.saveCount)")
                                .typography(.labelLarge)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(Color.green.gradient)
                        .disabled(!voiceViewModel.canSave)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                voiceControls
            }
            .sheet(isPresented: $showReceiptScan) {
                ReceiptScanSheet(
                    date: vm.date,
                    store: store,
                    settingsStore: settingsStore,
                    onSaved: { dismiss() }
                )
            }
            .navigationDestination(isPresented: $vm.showCatalog) {
                SubscriptionCatalogView(viewModel: viewModel)
            }
            .navigationDestination(isPresented: $showBatchAdd) {
                BatchAddView(
                    date: vm.date,
                    store: store,
                    settingsStore: settingsStore,
                    onDone: { dismiss() }
                )
            }
            .navigationDestination(item: $vm.selectedService) { service in
                ExpenseFormView(
                    mode: .create(template: service, date: vm.date),
                    store: store,
                    settingsStore: settingsStore,
                    onCommit: { _ in dismiss() }
                )
            }
            .navigationDestination(item: $vm.blankRoute) { route in
                ExpenseFormView(
                    mode: .createBlank(name: route.name, date: vm.date),
                    store: store,
                    settingsStore: settingsStore,
                    onCommit: { _ in dismiss() }
                )
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            if currencyCode.isEmpty {
                currencyCode = settingsStore.settings.currencyCode
            }
        }
        .sheet(isPresented: keypadBinding) {
            if let index = keypadItemIndex {
                NumKeyPadSheet(
                    amount: $voiceViewModel.items[index].amount,
                    currencyCode: $currencyCode,
                    typingStyle: .decimal
                ) {
                    keypadItemID = nil
                }
                .environment(settingsStore)
                .presentationDetents([.height(560)])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Bento hub

    private func bentoGrid(vm: ExpenseTemplateSheetViewModel) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                AddOptionCard(
                    icon: "doc.text.viewfinder",
                    title: "Scan with Camera",
                    minHeight: 172
                ) { showReceiptScan = true }

                VStack(spacing: 12) {
                    AddOptionCard(
                        icon: "square.and.pencil",
                        title: "Add Custom",
                        minHeight: 80
                    ) { vm.createBlank() }

                    AddOptionCard(
                        icon: "list.bullet.rectangle",
                        title: "Add Multiple",
                        minHeight: 80
                    ) { showBatchAdd = true }
                }
            }

            HStack(spacing: 12) {
                AddOptionCard(
                    icon: "square.grid.2x2",
                    title: "Add Subscriptions",
                    minHeight: 110
                ) { vm.showCatalog = true }

                AddOptionCard(
                    icon: "square.and.arrow.down",
                    title: "Import from Sheet, Notion",
                    badge: "Coming soon",
                    isEnabled: false,
                    minHeight: 110
                ) {}
            }
        }
    }

    // MARK: - Voice review list

    private var voiceReviewList: some View {
        @Bindable var voice = voiceViewModel

        return VStack(spacing: 12) {
            if voice.items.isEmpty {
                // Listening/processing with nothing parsed yet — fill the
                // sheet instead of collapsing to zero height.
                VStack(spacing: 14) {
                    Image(systemName: "waveform")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(Color.appPurple)
                        .symbolEffect(.variableColor.iterative, isActive: true)
                    Text(voice.isProcessing ? "Adding…" : "Listening…")
                        .typography(.titleMedium)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .containerRelativeFrame(.vertical) { length, _ in length * 0.7 }
            }

            ForEach($voice.items) { $item in
                itemRow($item)
            }

            if !voice.items.isEmpty {
                totalRow

                AppButton(
                    title: "Add Item",
                    icon: "plus",
                    style: .secondary,
                    appearance: .outline,
                    expands: true
                ) {
                    withAnimation(.spring(duration: 0.35)) {
                        voiceViewModel.addBlankItem()
                    }
                }
            }
        }
    }

    private func itemRow(_ item: Binding<ParsedExpense>) -> some View {
        GlassSection {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Logo matched from the spoken name: template artwork for
                    // known services, seeded symbol + color otherwise.
                    LogoCircle(
                        size: 44,
                        customization: voiceViewModel.customization(for: item.wrappedValue),
                        logoName: SubscriptionTemplate.logoName(for: item.wrappedValue.name),
                        name: item.wrappedValue.name
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
                            voiceViewModel.items.removeAll { $0.id == item.wrappedValue.id }
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

                    Text(voiceViewModel.dateLabel(for: item.wrappedValue))
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
            ForEach(voiceViewModel.categories) { category in
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
        guard let category = voiceViewModel.categories.first(where: { $0.name == name }) else {
            return Color.gray
        }
        return Color(hex: category.colorHex)
    }

    private var totalRow: some View {
        HStack {
            Text("\(voiceViewModel.saveCount) item\(voiceViewModel.saveCount == 1 ? "" : "s")")
            Spacer()
            Text(
                MoneyFormatter.format(
                    voiceViewModel.totalPrice,
                    settings: settingsStore.settings
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
        return voiceViewModel.items.firstIndex { $0.id == id }
    }

    private var keypadBinding: Binding<Bool> {
        Binding(
            get: { keypadItemID != nil },
            set: { if !$0 { keypadItemID = nil } }
        )
    }

    // MARK: - Hold & Speak (bottom)

    @ViewBuilder
    private var voiceControls: some View {
        let voice = voiceViewModel

        GlassSection {
            VStack(spacing: 10) {
                if voice.isRecording && !voice.transcript.isEmpty {
                    Text(voice.transcript)
                        .typography(.bodyMedium)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                if let message = voice.errorMessage {
                    VStack(spacing: 6) {
                        Text(message)
                            .typography(.bodySmall)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                        if voice.micDenied {
                            Button("Open Settings") {
                                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                                UIApplication.shared.open(url)
                            }
                            .typography(.labelLarge)
                        }
                    }
                } else if !voice.isRecording && !voice.isProcessing {
                    Text("Try holding and speak your expenses")
                        .typography(.labelMedium)
                        .foregroundStyle(.secondary)
                }

                holdButton
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 8)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .animation(.spring(duration: 0.3), value: voice.isRecording)
        .animation(.spring(duration: 0.3), value: voice.transcript.isEmpty)
    }

    @ViewBuilder
    private var holdButton: some View {
        let voice = voiceViewModel

        HStack(spacing: 10) {
            if voice.isProcessing {
                ProgressView()
                    .tint(.white)
                Text("Adding…")
            } else {
                Image(systemName: voice.isRecording ? "waveform" : "mic.fill")
                    .font(.system(size: 24, weight: .medium))
                    .symbolEffect(.variableColor.iterative, isActive: voice.isRecording)
                Text(voice.isRecording ? "Release to add" : "Hold & Speak")
            }
        }
        .typography(.titleMedium)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 76)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill((voice.isRecording ? Color.red : Color.appPurple).gradient)
        )
        .scaleEffect(voice.isRecording ? 1.02 : 1)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in voiceViewModel.beginHold() }
                .onEnded { _ in voiceViewModel.endHold() }
        )
        .allowsHitTesting(!voice.isProcessing)
    }
}

/// Tappable bento tile: icon + title, optional "Coming soon" badge. Vertical
/// by default; `.horizontal` for full-width rows. `tint` fills the tile with
/// a vivid accent.
private struct AddOptionCard: View {
    enum CardLayout { case vertical, horizontal }

    let icon: String
    let title: String
    var badge: String? = nil
    var isEnabled: Bool = true
    var minHeight: CGFloat = 140
    var layout: CardLayout = .vertical
    var tint: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                switch layout {
                case .vertical:
                    VStack(spacing: 10) { labelContent }
                case .horizontal:
                    HStack(spacing: 12) { labelContent }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .background(tint.map { AnyShapeStyle($0.gradient) } ?? AnyShapeStyle(Color.gray.opacity(0.15)))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private var foreground: Color {
        if tint != nil { return .white }
        return isEnabled ? .primary : .secondary
    }

    @ViewBuilder
    private var labelContent: some View {
        Image(systemName: icon)
            .font(.system(size: layout == .horizontal ? 22 : 30, weight: .medium))
            .foregroundStyle(foreground)

        Text(title)
            .typography(layout == .horizontal ? .titleSmall : .bodyMedium)
            .foregroundStyle(foreground)
            .multilineTextAlignment(.center)

        if let badge {
            Text(badge)
                .typography(.labelMedium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.primary.opacity(0.08)))
        }
    }
}

#Preview {
    ExpenseTemplateSheetPreviewHost()
}
