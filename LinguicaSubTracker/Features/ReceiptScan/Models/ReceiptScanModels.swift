import Foundation
import CoreGraphics

/// One recognized word from the Vision OCR pass.
/// `boundingBox` is in Vision's normalized coordinate space (origin bottom-left).
struct OCRToken {
    let text: String
    let boundingBox: CGRect
    let confidence: Float

    var centerX: CGFloat { boundingBox.midX }
    var centerY: CGFloat { boundingBox.midY }
}

/// Tokens grouped into a visual line, sorted left-to-right.
struct OCRLine {
    let tokens: [OCRToken]

    var text: String {
        tokens.map(\.text).joined(separator: " ")
    }

    var centerY: CGFloat {
        guard !tokens.isEmpty else { return 0 }
        return tokens.reduce(0) { $0 + $1.centerY } / CGFloat(tokens.count)
    }

    var height: CGFloat {
        guard !tokens.isEmpty else { return 0 }
        return tokens.reduce(0) { $0 + $1.boundingBox.height } / CGFloat(tokens.count)
    }

    var confidence: Float {
        guard !tokens.isEmpty else { return 0 }
        return tokens.reduce(0) { $0 + $1.confidence } / Float(tokens.count)
    }
}

/// A parsed line item, editable in the review UI before saving.
struct ScannedExpenseItem: Identifiable, Equatable {
    let id: UUID
    var name: String
    var price: Double
    var confidence: Float

    init(id: UUID = UUID(), name: String, price: Double, confidence: Float) {
        self.id = id
        self.name = name
        self.price = price
        self.confidence = confidence
    }
}

enum ReceiptScanError: LocalizedError {
    case invalidImage
    case recognitionFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Couldn't read that image."
        case .recognitionFailed: return "Text recognition failed."
        }
    }
}
