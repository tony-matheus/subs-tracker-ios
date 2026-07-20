import Foundation
import Observation
import PhotosUI
import SwiftUI

@Observable
@MainActor
final class ReceiptScanViewModel {

    enum Stage {
        case capture
        case processing
        case review
    }

    var stage: Stage = .capture
    var items: [ScannedExpenseItem] = []
    var errorMessage: String?

    var showDocumentCamera = false
    var photoItem: PhotosPickerItem?

    let date: Date
    let store: AppStore
    let settingsStore: SettingsStore

    init(date: Date, store: AppStore, settingsStore: SettingsStore) {
        self.date = date
        self.store = store
        self.settingsStore = settingsStore
    }

    // MARK: - Input

    func process(images: [UIImage]) async {
        guard !images.isEmpty else { return }
        stage = .processing
        errorMessage = nil

        var found: [ScannedExpenseItem] = []
        do {
            for image in images {
                let tokens = try await ReceiptOCRService.recognizeTokens(in: image)
                found += ReceiptParser.items(from: tokens)
            }
        } catch {
            errorMessage = error.localizedDescription
            stage = .capture
            return
        }

        if found.isEmpty {
            errorMessage = "No items found on that receipt. Try a clearer photo, or add items manually."
        }
        items = found
        stage = .review
    }

    func loadPhoto(_ item: PhotosPickerItem) async {
        stage = .processing
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data)
        else {
            errorMessage = ReceiptScanError.invalidImage.localizedDescription
            stage = .capture
            photoItem = nil
            return
        }
        photoItem = nil
        await process(images: [image])
    }

    // MARK: - Review edits

    func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }

    func addBlankItem() {
        items.append(ScannedExpenseItem(name: "", price: 0, confidence: 1))
    }

    func rescan() {
        items = []
        errorMessage = nil
        stage = .capture
    }

    // MARK: - Saving

    private var validItems: [ScannedExpenseItem] {
        items.filter {
            !$0.name.trimmingCharacters(in: .whitespaces).isEmpty && $0.price > 0
        }
    }

    var canSave: Bool { !validItems.isEmpty }

    var saveCount: Int { validItems.count }

    var totalPrice: Double {
        validItems.reduce(0) { $0 + $1.price }
    }

    /// Persists every valid item as a one-time expense on the scan date.
    func saveAll() {
        for item in validItems {
            let expense = Expense(
                name: item.name.trimmingCharacters(in: .whitespaces),
                price: item.price,
                billingCycle: .oneTime,
                type: .expense,
                startDate: date,
                category: "Entertainment",
                list: "Personal"
            )
            store.add(expense)
        }
    }
}
