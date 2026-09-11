import SwiftUI

struct ApplePayImportSheet: View {
    @State private var viewModel: ApplePayImportViewModel
    @Environment(\.dismiss) private var dismiss

    let store: AppStore
    let settingsStore: SettingsStore

    init(date: Date = Date(), store: AppStore, settingsStore: SettingsStore) {
        self.store = store
        self.settingsStore = settingsStore
        _viewModel = State(
            initialValue: ApplePayImportViewModel(
                date: date,
                store: store,
                settingsStore: settingsStore
            )
        )
    }

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard

                    quickActionsGrid

                    if !vm.transactions.isEmpty {
                        selectionToolbar
                        transactionList
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .appBackground()
            .navigationTitle("Apple Pay Import")
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
            .safeAreaInset(edge: .bottom) {
                if !vm.transactions.isEmpty {
                    bottomImportBar
                }
            }
            .sheet(isPresented: $vm.showShortcutGuide) {
                ApplePayShortcutGuideView()
            }
            .sheet(isPresented: $vm.showRawTextInput) {
                ApplePayRawTextImportSheet(currencyCode: settingsStore.settings.currencyCode) { pastedText in
                    vm.parseAndAddRawText(pastedText)
                }
            }
            .overlay(alignment: .top) {
                if vm.showSuccessToast {
                    successToast
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                }
            }
        }
    }

    // MARK: - Header & Quick Actions

    private var headerCard: some View {
        GlassSection {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black)
                        .frame(width: 50, height: 50)
                    HStack(spacing: 2) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18, weight: .bold))
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 16))
                    }
                    .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Pay Sync & Import")
                        .typography(.titleMedium)
                        .foregroundStyle(.primary)
                    Text("Auto-detect categories & values from Apple Pay transactions.")
                        .typography(.bodySmall)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var quickActionsGrid: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.showShortcutGuide = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.shield.fill")
                        .foregroundStyle(Color.appPurple)
                    Text("Auto Setup")
                        .typography(.labelLarge)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.appPurple.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            }

            Button {
                viewModel.showRawTextInput = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.clipboard.fill")
                        .foregroundStyle(Color.blue)
                    Text("Paste Text")
                        .typography(.labelLarge)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            }

            Button {
                viewModel.loadSampleData()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(Color.green)
                    Text("Demo Data")
                        .typography(.labelLarge)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Selection Toolbar & List

    private var selectionToolbar: some View {
        HStack {
            Text("\(viewModel.selectedCount) of \(viewModel.transactions.count) selected")
                .typography(.labelMedium)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Select All") {
                viewModel.selectAll()
            }
            .typography(.labelMedium)
            .foregroundStyle(Color.appPurple)

            Text("•")
                .foregroundStyle(.secondary)

            Button("Deselect") {
                viewModel.deselectAll()
            }
            .typography(.labelMedium)
            .foregroundStyle(.secondary)

            Text("•")
                .foregroundStyle(.secondary)

            Button("Clear All") {
                withAnimation {
                    viewModel.clearAll()
                }
            }
            .typography(.labelMedium)
            .foregroundStyle(.red)
        }
        .padding(.horizontal, 4)
    }

    private var transactionList: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.transactions) { tx in
                transactionRow(tx)
            }
        }
    }

    private func transactionRow(_ tx: ApplePayTransaction) -> some View {
        GlassSection {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    // Checkbox
                    Button {
                        viewModel.toggleSelection(for: tx.id)
                    } label: {
                        Image(systemName: tx.isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundStyle(tx.isSelected ? Color.appPurple : Color.gray.opacity(0.5))
                    }
                    .buttonStyle(.plain)

                    // Logo
                    LogoCircle(
                        size: 40,
                        customization: LogoCustomization.resolved(for: tx.id, name: tx.merchant, in: store),
                        logoName: SubscriptionTemplate.logoName(for: tx.merchant),
                        name: tx.merchant
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(tx.merchant)
                            .typography(.titleSmall)
                            .foregroundStyle(.primary)

                        Text(tx.notes ?? tx.paymentMethod)
                            .typography(.bodySmall)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(MoneyFormatter.format(tx.amount, settings: settingsStore.settings))
                            .typography(.titleSmall)
                            .foregroundStyle(.primary)

                        Text(formattedDate(tx.date))
                            .typography(.labelMedium)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        withAnimation {
                            viewModel.removeTransaction(id: tx.id)
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Divider()

                HStack {
                    Text("Category:")
                        .typography(.labelMedium)
                        .foregroundStyle(.secondary)

                    Spacer()

                    categoryMenu(for: tx)
                }
            }
        }
    }

    private func categoryMenu(for tx: ApplePayTransaction) -> some View {
        let color = categoryColor(for: tx.category)

        return Menu {
            ForEach(viewModel.availableCategories) { cat in
                Button(cat.name) {
                    viewModel.updateCategory(for: tx.id, category: cat.name)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(tx.category)
                    .typography(.bodyMedium.weight(.semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(color.contrastingForeground)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(color))
        }
    }

    private func categoryColor(for name: String) -> Color {
        guard let cat = viewModel.availableCategories.first(where: { $0.name == name }) else {
            return Color.gray
        }
        return Color(hex: cat.colorHex)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.and.123")
                .font(.system(size: 48))
                .foregroundStyle(Color.appPurple)
                .padding(.top, 24)

            Text("No Pending Transactions")
                .typography(.titleMedium)
                .foregroundStyle(.primary)

            Text("Tap 'Paste Text' to import statement text, or configure 'Auto Setup' to capture Apple Pay payments live on your iPhone.")
                .typography(.bodySmall)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            HStack(spacing: 12) {
                AppButton(
                    title: "Paste Text",
                    icon: "doc.on.clipboard.fill",
                    style: .primary,
                    expands: false
                ) {
                    viewModel.showRawTextInput = true
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
    }

    // MARK: - Bottom Import Bar

    private var bottomImportBar: some View {
        GlassSection {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Selected")
                        .typography(.labelMedium)
                        .foregroundStyle(.secondary)
                    Text(MoneyFormatter.format(viewModel.selectedTotalAmount, settings: settingsStore.settings))
                        .typography(.titleMedium)
                        .foregroundStyle(.primary)
                }

                Spacer()

                AppButton(
                    title: viewModel.isProcessing ? "Importing..." : "Import \(viewModel.selectedCount) Items",
                    icon: "square.and.arrow.down.fill",
                    style: .primary,
                    expands: false
                ) {
                    viewModel.importSelectedTransactions {
                        dismiss()
                    }
                }
                .disabled(viewModel.selectedCount == 0 || viewModel.isProcessing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 6)
    }

    private var successToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Imported \(viewModel.importedCount) Apple Pay expenses successfully!")
                .typography(.labelLarge)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(radius: 8)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ApplePayImportSheet(
        store: AppStore(),
        settingsStore: SettingsStore()
    )
}
