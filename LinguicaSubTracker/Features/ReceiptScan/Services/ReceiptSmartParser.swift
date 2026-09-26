import Foundation
import FoundationModels

@Generable
struct GeneratedReceipt {
    @Guide(description: "Every purchased line item on the receipt. Never totals, subtotals, tax, tips, discounts, payment, cash or change lines.")
    var items: [GeneratedReceiptItem]
}

@Generable
struct GeneratedReceiptItem {
    @Guide(description: "The item's name as printed, cleaned up and capitalized, without quantities or codes.")
    var name: String

    @Guide(description: "The item's line price exactly as printed, as a decimal number without currency symbol.")
    var price: Double

    @Guide(description: "The single best-matching category name, chosen ONLY from the allowed list given in the instructions.")
    var category: String
}

/// Receipt items read by the on-device language model, grounded against the
/// OCR so it can't invent amounts. Falls back to the heuristic `ReceiptParser`
/// when the model is unavailable, fails, or nothing survives grounding.
enum ReceiptSmartParser {

    static func items(from tokens: [OCRToken], categories: [String]) async -> [ScannedExpenseItem] {
        #if FF_SMART_RECEIPTS
        if let natural = await naturalItems(from: tokens, categories: categories) { return natural }
        #endif
        return ReceiptParser.items(from: tokens)
    }

    static func naturalItems(from tokens: [OCRToken], categories: [String]) async -> [ScannedExpenseItem]? {
        guard case .available = SystemLanguageModel.default.availability else { return nil }
        let text = ReceiptParser.groupIntoLines(tokens).map(\.text).joined(separator: "\n")
        guard !text.isEmpty else { return nil }

        let session = LanguageModelSession(instructions: """
            You read OCR text from a store receipt and list the purchased items.
            Each item has a name, its line price and a category. The category \
            MUST be exactly one of: \(categories.joined(separator: ", ")). \
            If none clearly fits, use "Other".
            """)
        guard let receipt = try? await session.respond(to: text, generating: GeneratedReceipt.self).content
        else { return nil }

        let items = grounded(
            receipt.items.map { (name: $0.name, price: $0.price, category: $0.category) },
            in: tokens,
            categories: categories
        )
        return items.isEmpty ? nil : items
    }

    /// Keeps only candidates whose price is printed on the receipt (drops
    /// invented or computed amounts) and whose name isn't a summary line.
    /// Confidence comes from the OCR token that printed that price.
    static func grounded(
        _ candidates: [(name: String, price: Double, category: String)],
        in tokens: [OCRToken],
        categories: [String]
    ) -> [ScannedExpenseItem] {
        var confidenceByCents: [Int: Float] = [:]
        for token in tokens {
            guard let value = ReceiptParser.priceValue(from: token.text) else { continue }
            let cents = Int((value * 100).rounded())
            confidenceByCents[cents] = max(confidenceByCents[cents] ?? 0, token.confidence)
        }

        return candidates.compactMap { candidate in
            let name = candidate.name.trimmingCharacters(in: .whitespaces)
            let lowered = name.lowercased()
            guard name.count >= 2, candidate.price > 0,
                  !ReceiptParser.noiseKeywords.contains(where: { lowered.contains($0) }),
                  let confidence = confidenceByCents[Int((candidate.price * 100).rounded())]
            else { return nil }
            return ScannedExpenseItem(
                name: name,
                price: candidate.price,
                confidence: confidence,
                category: VoiceExpenseParser.snapCategory(candidate.category, to: categories)
            )
        }
    }
}
