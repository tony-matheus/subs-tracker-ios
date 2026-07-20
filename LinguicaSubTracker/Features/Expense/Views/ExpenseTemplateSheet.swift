import SwiftUI

/// Entry point for adding an expense: a 2-column hub of add methods
/// (scan / custom / subscription catalog / import), each drilling into its
/// own flow on this sheet's navigation stack.
struct ExpenseTemplateSheet: View {
    @State private var viewModel: ExpenseTemplateSheetViewModel
    @State private var showReceiptScan: Bool = false
    @State private var showBatchAdd: Bool = false
    @State private var showVoiceAdd: Bool = false
    @Environment(\.dismiss) private var dismiss

    let store: AppStore
    let settingsStore: SettingsStore

    init(date: Date, store: AppStore, settingsStore: SettingsStore) {
        self.store = store
        self.settingsStore = settingsStore
        _viewModel = State(
            initialValue: ExpenseTemplateSheetViewModel(date: date)
        )
    }

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            ScrollView {
                // Bento layout: hero scan tile, compact utility tiles, and a
                // full-width voice CTA anchoring the bottom.
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

                    AddOptionCard(
                        icon: "mic.fill",
                        title: "Speak Your Expenses",
                        minHeight: 76,
                        layout: .horizontal,
                        tint: .purple
                    ) { showVoiceAdd = true }
                }
                .padding()
            }
            .appBackground()
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .sheet(isPresented: $showReceiptScan) {
                ReceiptScanSheet(
                    date: vm.date,
                    store: store,
                    settingsStore: settingsStore,
                    onSaved: { dismiss() }
                )
            }
            .sheet(isPresented: $showVoiceAdd) {
                VoiceAddSheet(
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
    }
}

/// Tappable bento tile: icon + title, optional "Coming soon" badge. Vertical
/// by default; `.horizontal` for full-width rows. `tint` fills the tile with
/// a vivid accent (used by the voice CTA).
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
