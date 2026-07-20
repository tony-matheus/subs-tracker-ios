import CoreGraphics
import Testing

@testable import LinguicaSubTracker

/// Builds synthetic OCR tokens laid out like a real receipt: normalized
/// coordinates, origin bottom-left (Vision convention), one row per line
/// from top (y near 1) to bottom (y near 0).
private func receiptTokens(_ rows: [[String]], confidence: Float = 0.95) -> [OCRToken] {
    let lineHeight: CGFloat = 0.03
    var tokens: [OCRToken] = []
    for (rowIndex, words) in rows.enumerated() {
        let y = 0.95 - CGFloat(rowIndex) * (lineHeight * 2)
        var x: CGFloat = 0.05
        for (wordIndex, word) in words.enumerated() {
            // Last word on a row is right-aligned like a price column.
            let width = CGFloat(word.count) * 0.02
            let minX = wordIndex == words.count - 1 && words.count > 1 ? 0.85 - width / 2 : x
            tokens.append(
                OCRToken(
                    text: word,
                    boundingBox: CGRect(x: minX, y: y, width: width, height: lineHeight),
                    confidence: confidence
                )
            )
            x = minX + width + 0.02
        }
    }
    return tokens
}

struct ReceiptParserTests {

    // MARK: - Price parsing

    @Test func parsesPlainPrice() {
        #expect(ReceiptParser.priceValue(from: "5.50") == 5.50)
    }

    @Test func parsesCurrencyAndCommaDecimal() {
        #expect(ReceiptParser.priceValue(from: "$12.99") == 12.99)
        #expect(ReceiptParser.priceValue(from: "€7,20") == 7.20)
        #expect(ReceiptParser.priceValue(from: "1,234.56") == 1234.56)
    }

    @Test func toleratesTrailingTaxFlag() {
        #expect(ReceiptParser.priceValue(from: "5.99T") == 5.99)
    }

    @Test func rejectsNonPrices() {
        #expect(ReceiptParser.priceValue(from: "599") == nil)        // quantity/SKU
        #expect(ReceiptParser.priceValue(from: "-5.00") == nil)      // refund
        #expect(ReceiptParser.priceValue(from: "10:52") == nil)      // time
        #expect(ReceiptParser.priceValue(from: "07/02/2026") == nil) // date
        #expect(ReceiptParser.priceValue(from: "Latte") == nil)
    }

    // MARK: - Line grouping

    @Test func groupsTokensIntoRows() {
        let tokens = receiptTokens([
            ["Latte", "5.50"],
            ["Bagel", "3.20"],
        ])
        let lines = ReceiptParser.groupIntoLines(tokens)
        #expect(lines.count == 2)
        #expect(lines[0].text == "Latte 5.50")
        #expect(lines[1].text == "Bagel 3.20")
    }

    // MARK: - Full pipeline

    @Test func extractsItemsAndDropsSummaryLines() {
        let tokens = receiptTokens([
            ["CORNER", "CAFE"],
            ["123", "Main", "Street"],
            ["Latte", "5.50"],
            ["Sesame", "Bagel", "3.20"],
            ["Orange", "Juice", "4.00"],
            ["SUBTOTAL", "12.70"],
            ["TAX", "1.65"],
            ["TOTAL", "14.35"],
            ["CASH", "20.00"],
            ["CHANGE", "5.65"],
        ])
        let items = ReceiptParser.items(from: tokens)

        #expect(items.count == 3)
        #expect(items[0].name == "Latte")
        #expect(items[0].price == 5.50)
        #expect(items[1].name == "Sesame Bagel")
        #expect(items[1].price == 3.20)
        #expect(items[2].name == "Orange Juice")
        #expect(items[2].price == 4.00)
    }

    @Test func picksLineTotalOverUnitPriceViaColumn() {
        // "2 x 2.75 → 5.50": quantity line where the rightmost/column price
        // must win over the unit price.
        let tokens = receiptTokens([
            ["Latte", "5.50"],
            ["2", "Muffin", "2.75", "5.50"],
            ["Bagel", "3.20"],
        ])
        let items = ReceiptParser.items(from: tokens)

        #expect(items.count == 3)
        let muffin = items.first { $0.name.contains("Muffin") }
        #expect(muffin?.price == 5.50)
    }

    @Test func stripsQuantityPrefixFromName() {
        let tokens = receiptTokens([
            ["2", "x", "Croissant", "7.00"],
        ])
        let items = ReceiptParser.items(from: tokens)
        #expect(items.count == 1)
        #expect(items[0].name == "Croissant")
        #expect(items[0].price == 7.00)
    }

    @Test func dropsLowConfidenceLines() {
        let tokens = receiptTokens([["Latte", "5.50"]], confidence: 0.3)
        #expect(ReceiptParser.items(from: tokens).isEmpty)
    }

    @Test func dropsPriceOnlyLines() {
        let tokens = receiptTokens([["5.50"]])
        #expect(ReceiptParser.items(from: tokens).isEmpty)
    }

    @Test func emptyInputYieldsNoItems() {
        #expect(ReceiptParser.items(from: []).isEmpty)
    }
}
