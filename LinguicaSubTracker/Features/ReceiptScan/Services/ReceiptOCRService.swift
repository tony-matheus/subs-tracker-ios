import Foundation
import UIKit
import Vision

/// On-device OCR over a still receipt image using the Vision framework.
/// Emits word-level tokens with normalized bounding boxes so the parser can
/// reason spatially (line grouping, price-column detection).
enum ReceiptOCRService {

    nonisolated static func recognizeTokens(in image: UIImage) async throws -> [OCRToken] {
        guard let cgImage = image.cgImage else { throw ReceiptScanError.invalidImage }
        return try await recognizeTokens(in: cgImage, orientation: CGImagePropertyOrientation(image.imageOrientation))
    }

    /// iOS 26 document recognition when `FF_SMART_RECEIPTS` is on (reads
    /// receipt layout as structured lines); classic text recognition otherwise,
    /// or when the document pass finds nothing.
    nonisolated static func recognizeTokens(
        in cgImage: CGImage,
        orientation: CGImagePropertyOrientation
    ) async throws -> [OCRToken] {
        #if FF_SMART_RECEIPTS
        if let tokens = try? await documentTokens(in: cgImage, orientation: orientation), !tokens.isEmpty {
            return tokens
        }
        #endif
        return try await textTokens(in: cgImage, orientation: orientation)
    }

    nonisolated static func documentTokens(
        in cgImage: CGImage,
        orientation: CGImagePropertyOrientation
    ) async throws -> [OCRToken] {
        let documents = try await RecognizeDocumentsRequest().perform(on: cgImage, orientation: orientation)
        var result: [OCRToken] = []
        for document in documents {
            for line in document.document.text.lines {
                guard let candidate = line.topCandidates(1).first else { continue }
                result += wordTokens(
                    candidate.string,
                    confidence: candidate.confidence,
                    lineBox: line.boundingBox.cgRect
                ) { candidate.boundingBox(for: $0)?.boundingBox.cgRect }
            }
        }
        return result
    }

    private nonisolated static func textTokens(
        in cgImage: CGImage,
        orientation: CGImagePropertyOrientation
    ) async throws -> [OCRToken] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true

                let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])

                do {
                    try handler.perform([request])
                    let tokens = (request.results ?? []).flatMap { observation -> [OCRToken] in
                        guard let candidate = observation.topCandidates(1).first else { return [] }
                        return wordTokens(
                            candidate.string,
                            confidence: candidate.confidence,
                            lineBox: observation.boundingBox
                        ) { (try? candidate.boundingBox(for: $0))?.boundingBox }
                    }
                    continuation.resume(returning: tokens)
                } catch {
                    continuation.resume(throwing: ReceiptScanError.recognitionFailed)
                }
            }
        }
    }

    /// Splits a recognized line into word tokens, resolving a bounding box
    /// per word (falling back to the line's) so downstream spatial matching
    /// works on token granularity.
    private nonisolated static func wordTokens(
        _ fullText: String,
        confidence: Float,
        lineBox: CGRect,
        box: (Range<String.Index>) -> CGRect?
    ) -> [OCRToken] {
        var result: [OCRToken] = []
        var cursor = fullText.startIndex
        for word in fullText.split(separator: " ") {
            guard let range = fullText.range(of: String(word), range: cursor..<fullText.endIndex) else { continue }
            cursor = range.upperBound
            result.append(OCRToken(text: String(word), boundingBox: box(range) ?? lineBox, confidence: confidence))
        }
        return result
    }
}

extension CGImagePropertyOrientation {
    nonisolated init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
