import Foundation
import CoreGraphics

/// Deterministic receipt structure parser. Turns raw OCR tokens into line
/// items via XY line grouping, heuristic scoring, and price-column matching.
/// Pure functions — no I/O, fully testable.
enum ReceiptParser {

    // MARK: - Tuning

    /// A line must score at least this to count as an item.
    private static let itemScoreThreshold = 4

    /// Lines whose text contains any of these are receipt summary/metadata,
    /// never purchasable items.
    private static let noiseKeywords: [String] = [
        "total", "subtotal", "sub-total", "tax", "hst", "gst", "pst", "vat",
        "change", "cash", "credit", "debit", "visa", "mastercard", "amex",
        "balance", "amount due", "tender", "tip", "gratuity", "payment",
        "approval", "auth", "invoice", "cashier", "thank", "loyalty",
        "points", "savings", "discount", "refund",
    ]

    private static let minConfidence: Float = 0.5
    private static let maxReasonablePrice: Double = 100_000

    // MARK: - Pipeline

    nonisolated static func items(from tokens: [OCRToken]) -> [ScannedExpenseItem] {
        let lines = groupIntoLines(tokens)

        // First pass: score every line and find its best price token.
        var candidates: [(line: OCRLine, priceIndex: Int, price: Double)] = []
        for line in lines {
            guard score(line) >= itemScoreThreshold else { continue }
            guard let (index, value) = bestPriceToken(in: line, columnX: nil) else { continue }
            candidates.append((line, index, value))
        }

        // Column detection: median X of the chosen price tokens. Re-associate
        // prices against the column so quantity/unit-price columns lose out.
        let columnX = medianPriceColumnX(of: candidates)

        var items: [ScannedExpenseItem] = []
        for candidate in candidates {
            let (index, value) = bestPriceToken(in: candidate.line, columnX: columnX)
                ?? (candidate.priceIndex, candidate.price)

            guard value > 0, value < maxReasonablePrice else { continue }
            guard let name = itemName(from: candidate.line, priceIndex: index) else { continue }

            let priceConfidence = candidate.line.tokens[index].confidence
            items.append(
                ScannedExpenseItem(
                    name: name,
                    price: value,
                    confidence: min(candidate.line.confidence, priceConfidence)
                )
            )
        }
        return items
    }

    // MARK: - Layout reconstruction

    /// XY grouping: sort by Y (Vision origin is bottom-left, so descending Y
    /// = top of receipt first), then cluster tokens whose vertical centers
    /// fall within half a line height. Tokens inside a line sort by X.
    nonisolated static func groupIntoLines(_ tokens: [OCRToken]) -> [OCRLine] {
        guard !tokens.isEmpty else { return [] }

        let heights = tokens.map(\.boundingBox.height).sorted()
        let medianHeight = max(heights[heights.count / 2], 0.001)

        let sorted = tokens.sorted { $0.centerY > $1.centerY }

        var lines: [[OCRToken]] = []
        var current: [OCRToken] = [sorted[0]]
        var currentY = sorted[0].centerY

        for token in sorted.dropFirst() {
            if abs(token.centerY - currentY) < medianHeight * 0.5 {
                current.append(token)
                // Running average keeps slightly skewed receipts in one line.
                currentY = current.reduce(0) { $0 + $1.centerY } / CGFloat(current.count)
            } else {
                lines.append(current)
                current = [token]
                currentY = token.centerY
            }
        }
        lines.append(current)

        return lines.map { OCRLine(tokens: $0.sorted { $0.boundingBox.minX < $1.boundingBox.minX }) }
    }

    // MARK: - Scoring

    /// Weighted heuristic classification of a line as an item row.
    nonisolated static func score(_ line: OCRLine) -> Int {
        let text = line.text
        let lowered = text.lowercased()
        var score = 0

        // Ends with a price-shaped number.
        if let last = line.tokens.last, priceValue(from: last.text) != nil {
            score += 5
        }

        // Contains a currency symbol.
        if text.contains("$") || text.contains("€") || text.contains("£") {
            score += 3
        }

        // Text followed by a numeric value somewhere on the line.
        if hasTextThenNumber(line) {
            score += 2
        }

        // Summary/metadata keywords are hard negatives.
        if noiseKeywords.contains(where: { lowered.contains($0) }) {
            score -= 10
        }

        // Penalize shaky OCR.
        if line.confidence < minConfidence {
            score -= 5
        } else if line.confidence < 0.7 {
            score -= 2
        }

        return score
    }

    private nonisolated static func hasTextThenNumber(_ line: OCRLine) -> Bool {
        var sawText = false
        for token in line.tokens {
            let isNumeric = priceValue(from: token.text) != nil
                || token.text.allSatisfy(\.isNumber)
            if isNumeric, sawText { return true }
            if token.text.contains(where: \.isLetter) { sawText = true }
        }
        return false
    }

    // MARK: - Price association

    /// Picks the price token for a line. Defaults to the rightmost
    /// price-shaped token; when a price column X is known, prefers the
    /// candidate closest to that column (nearest-neighbor on the X axis).
    nonisolated static func bestPriceToken(
        in line: OCRLine,
        columnX: CGFloat?
    ) -> (index: Int, value: Double)? {
        let candidates: [(Int, Double)] = line.tokens.enumerated().compactMap { index, token in
            priceValue(from: token.text).map { (index, $0) }
        }
        guard !candidates.isEmpty else { return nil }

        if let columnX, candidates.count > 1 {
            let nearest = candidates.min {
                abs(line.tokens[$0.0].centerX - columnX) < abs(line.tokens[$1.0].centerX - columnX)
            }
            if let nearest { return nearest }
        }
        // Rightmost numeric token (line totals sit at the line end).
        return candidates.last
    }

    private nonisolated static func medianPriceColumnX(
        of candidates: [(line: OCRLine, priceIndex: Int, price: Double)]
    ) -> CGFloat? {
        guard candidates.count >= 2 else { return nil }
        let xs = candidates.map { $0.line.tokens[$0.priceIndex].centerX }.sorted()
        return xs[xs.count / 2]
    }

    // MARK: - Name extraction

    /// Everything left of the price token, minus quantity markers, SKU-like
    /// digit runs, and other price-shaped tokens.
    nonisolated static func itemName(from line: OCRLine, priceIndex: Int) -> String? {
        let nameTokens = line.tokens[..<priceIndex].filter { token in
            priceValue(from: token.text) == nil
                && !token.text.allSatisfy { $0.isNumber || $0.isPunctuation }
        }

        var name = nameTokens.map(\.text).joined(separator: " ")
        // Quantity markers: "2 x Latte", "2x Latte", or a leftover bare
        // "x Latte" once the digit token was filtered out above.
        name = name.replacingOccurrences(
            of: #"^(?:\d+\s*)?[xX@]\s+|^\d+\s+"#,
            with: "",
            options: .regularExpression
        )
        name = name.trimmingCharacters(in: CharacterSet(charactersIn: " -–—.*#:$€£"))

        guard name.count(where: \.isLetter) >= 2 else { return nil }
        return String(name.prefix(60))
    }

    // MARK: - Numeric parsing

    /// Parses a price-shaped string: optional currency symbol, digits with
    /// optional thousands separators, and a mandatory 2-digit decimal part
    /// ("." or ","). Trailing single-letter tax flags ("5.99T") are tolerated.
    /// Returns nil for negatives (refunds) and plain integers (quantities).
    nonisolated static func priceValue(from raw: String) -> Double? {
        var s = raw.trimmingCharacters(in: .whitespaces)
        guard !s.hasPrefix("-"), !s.hasPrefix("(") else { return nil }

        // Strip currency symbols and a trailing tax-flag letter.
        s = s.replacingOccurrences(of: #"^[\$€£]|\s"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: #"[A-Za-z]$"#, with: "", options: .regularExpression)

        guard s.range(
            of: #"^\d{1,6}(?:[.,]\d{3})*[.,]\d{2}$"#,
            options: .regularExpression
        ) != nil else { return nil }

        // Last separator is the decimal point; everything else is grouping.
        guard let decimalSeparator = s.lastIndex(where: { $0 == "." || $0 == "," }) else {
            return nil
        }
        let integerPart = s[..<decimalSeparator].filter(\.isNumber)
        let fractionPart = s[s.index(after: decimalSeparator)...]
        return Double("\(integerPart).\(fractionPart)")
    }
}
