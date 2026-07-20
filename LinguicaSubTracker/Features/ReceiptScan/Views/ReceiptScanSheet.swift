import PhotosUI
import SwiftUI

/// Scan a receipt → review extracted items → save each as a one-time expense.
struct ReceiptScanSheet: View {
    @State private var viewModel: ReceiptScanViewModel
    @Environment(\.dismiss) private var dismiss

    private let onSaved: () -> Void

    init(
        date: Date,
        store: AppStore,
        settingsStore: SettingsStore,
        onSaved: @escaping () -> Void = {}
    ) {
        _viewModel = State(
            initialValue: ReceiptScanViewModel(
                date: date,
                store: store,
                settingsStore: settingsStore
            )
        )
        self.onSaved = onSaved
    }

    private var currencySymbol: String {
        MoneyFormatter.symbol(for: viewModel.settingsStore.settings.currencyCode)
    }

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            Group {
                switch vm.stage {
                case .capture:
                    capturePage(vm: vm)
                case .processing:
                    processingPage
                case .review:
                    reviewPage(vm: vm)
                }
            }
            .appBackground()
            .navigationTitle(vm.stage == .review ? "Review Items" : "Scan Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                if vm.stage == .review {
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
            }
            .fullScreenCover(isPresented: $vm.showDocumentCamera) {
                DocumentCameraView(
                    onScan: { images in
                        vm.showDocumentCamera = false
                        Task { await vm.process(images: images) }
                    },
                    onCancel: { vm.showDocumentCamera = false }
                )
                .ignoresSafeArea()
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Capture

    @ViewBuilder
    private func capturePage(vm: ReceiptScanViewModel) -> some View {
        @Bindable var vm = vm

        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(.primary)

            VStack(spacing: 6) {
                Text("Scan a receipt")
                    .typography(.headlineSmall)
                    .foregroundStyle(.primary)
                Text("Every item and price is read on your device.\nNothing leaves your phone.")
                    .typography(.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let message = vm.errorMessage {
                Text(message)
                    .typography(.bodySmall)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()

            VStack(spacing: 12) {
                if DocumentCameraView.isSupported {
                    Button {
                        vm.showDocumentCamera = true
                    } label: {
                        captureButtonLabel(icon: "camera.fill", title: "Scan with Camera")
                    }
                    .buttonStyle(.plain)
                }

                PhotosPicker(selection: $vm.photoItem, matching: .images) {
                    captureButtonLabel(icon: "photo.on.rectangle", title: "Choose from Photos")
                }
                .onChange(of: vm.photoItem) { _, newItem in
                    guard let newItem else { return }
                    Task { await vm.loadPhoto(newItem) }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private func captureButtonLabel(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
            Text(title)
                .typography(.titleMedium)
        }
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.primary.opacity(0.08))
        )
    }

    // MARK: - Processing

    private var processingPage: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Reading receipt…")
                .typography(.bodyMedium)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Review

    @ViewBuilder
    private func reviewPage(vm: ReceiptScanViewModel) -> some View {
        @Bindable var vm = vm

        List {
            if let message = vm.errorMessage {
                Section {
                    Text(message)
                        .typography(.bodySmall)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }
            }

            Section {
                ForEach($vm.items) { $item in
                    itemRow(item: $item)
                }
                .onDelete { vm.deleteItems(at: $0) }

                Button {
                    vm.addBlankItem()
                } label: {
                    Label("Add Item", systemImage: "plus.circle.fill")
                        .typography(.titleSmall)
                        .foregroundStyle(.primary)
                }
                .listRowBackground(Color.primary.opacity(0.05))
            } footer: {
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
            }

            Section {
                Button {
                    vm.rescan()
                } label: {
                    Label("Rescan", systemImage: "camera.viewfinder")
                        .typography(.titleSmall)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func itemRow(item: Binding<ScannedExpenseItem>) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(confidenceColor(item.wrappedValue.confidence))
                .frame(width: 8, height: 8)

            TextField("Name", text: item.name)
                .typography(.bodyLarge)

            Spacer(minLength: 8)

            HStack(spacing: 2) {
                Text(currencySymbol)
                    .foregroundStyle(.secondary)
                TextField(
                    "0.00",
                    value: item.price,
                    format: .number.precision(.fractionLength(2))
                )
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            }
            .typography(.titleSmall)
        }
        .listRowBackground(Color.appSurface.opacity(0.6))
    }

    /// Green = trustworthy OCR, amber = double-check, red = probably wrong.
    private func confidenceColor(_ confidence: Float) -> Color {
        if confidence >= 0.8 { return .green }
        if confidence >= 0.5 { return .orange }
        return .red
    }
}
