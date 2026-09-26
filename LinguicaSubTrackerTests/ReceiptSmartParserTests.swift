import CoreGraphics
import Foundation
import FoundationModels
import Testing

@testable import LinguicaSubTracker

@MainActor
private func token(_ text: String, confidence: Float = 0.9) -> OCRToken {
    OCRToken(text: text, boundingBox: CGRect(x: 0, y: 0, width: 0.1, height: 0.02), confidence: confidence)
}

@MainActor
@Suite("Smart receipt parsing")
struct ReceiptSmartParserTests {
    let categories = ["Entertainment", "Lifestyle", "Other"]
    var tokens: [OCRToken] {
        [token("Latte"), token("4.50", confidence: 0.8), token("Bagel"), token("$3.25"), token("Total"), token("7.75")]
    }

    @Test("keeps items whose price is printed, with that token's confidence")
    func keepsGrounded() {
        let items = ReceiptSmartParser.grounded(
            [(name: "Latte", price: 4.5, category: "lifestyle"), (name: "Bagel", price: 3.25, category: "Food")],
            in: tokens, categories: categories
        )
        #expect(items.map(\.name) == ["Latte", "Bagel"])
        #expect(items[0].confidence == 0.8)
        #expect(items[0].category == "Lifestyle")
        #expect(items[1].category == "Other")  // unknown category snaps to Other
    }

    @Test("drops invented prices and summary lines")
    func dropsUngrounded() {
        let items = ReceiptSmartParser.grounded(
            [(name: "Muffin", price: 2.99, category: "Other"),   // price not on the receipt
             (name: "Total", price: 7.75, category: "Other"),    // printed, but a summary line
             (name: "X", price: 4.5, category: "Other")],        // name too short
            in: tokens, categories: categories
        )
        #expect(items.isEmpty)
    }

    @Test("with no model, falls back to the heuristic parser",
          .enabled(if: SystemLanguageModel.default.availability != .available))
    func fallback() async {
        let items = await ReceiptSmartParser.items(from: [], categories: categories)
        #expect(items == ReceiptParser.items(from: []))
    }
}
