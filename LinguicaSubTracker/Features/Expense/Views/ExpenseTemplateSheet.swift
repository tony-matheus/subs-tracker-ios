import SwiftUI

/// Entry point for adding an expense: a 2-column hub of add methods
/// (scan / custom / subscription catalog / import), each drilling into its
/// own flow on this sheet's navigation stack.
struct ExpenseTemplateSheet: View {
    @State private var viewModel: ExpenseTemplateSheetViewModel
    @State private var showReceiptScan: Bool = false
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
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                    ],
                    spacing: 12
                ) {
                    AddOptionCard(
                        icon: "doc.text.viewfinder",
                        title: "Scan with Camera"
                    ) { showReceiptScan = true }

                    AddOptionCard(
                        icon: "square.and.pencil",
                        title: "Add Custom Expense"
                    ) { vm.createBlank() }

                    AddOptionCard(
                        icon: "square.grid.2x2",
                        title: "Add Subscriptions"
                    ) { vm.showCatalog = true }

                    AddOptionCard(
                        icon: "square.and.arrow.down",
                        title: "Import from Sheet, Notion",
                        badge: "Coming soon",
                        isEnabled: false
                    ) {}
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
            .navigationDestination(isPresented: $vm.showCatalog) {
                SubscriptionCatalogView(viewModel: viewModel)
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

/// Large tappable hub card: icon + title, optional "Coming soon" badge.
private struct AddOptionCard: View {
    let icon: String
    let title: String
    var badge: String? = nil
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(isEnabled ? .primary : .secondary)

                Text(title)
                    .typography(.bodyMedium)
                    .foregroundStyle(isEnabled ? .primary : .secondary)
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
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 140)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

#Preview {
    ExpenseTemplateSheetPreviewHost()
}
