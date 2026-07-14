import Foundation
import UIKit
import Vision

/// On-device OCR over a still receipt image using the Vision framework.
/// Emits word-level tokens with normalized bounding boxes so the parser can
/// reason spatially (line grouping, price-column detection).
enum ReceiptOCRService {

    nonisolated static func recognizeTokens(in image: UIImage) async throws -> [OCRToken] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let cgImage = image.cgImage else {
                    continuation.resume(throwing: ReceiptScanError.invalidImage)
                    return
                }

                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true

                let handler = VNImageRequestHandler(
                    cgImage: cgImage,
                    orientation: CGImagePropertyOrientation(image.imageOrientation),
                    options: [:]
                )

                do {
                    try handler.perform([request])
                    let observations = request.results ?? []
                    continuation.resume(returning: tokens(from: observations))
                } catch {
                    continuation.resume(throwing: ReceiptScanError.recognitionFailed)
                }
            }
        }
    }

    /// Splits each recognized line into word tokens, resolving a bounding box
    /// per word so downstream spatial matching works on token granularity.
    private nonisolated static func tokens(
        from observations: [VNRecognizedTextObservation]
    ) -> [OCRToken] {
        var result: [OCRToken] = []

        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }
            let fullText = candidate.string

            var cursor = fullText.startIndex
            for word in fullText.split(separator: " ") {
                guard let range = fullText.range(of: String(word), range: cursor..<fullText.endIndex) else {
                    continue
                }
                cursor = range.upperBound

                let box = (try? candidate.boundingBox(for: range))?.boundingBox
                    ?? observation.boundingBox

                result.append(
                    OCRToken(
                        text: String(word),
                        boundingBox: box,
                        confidence: candidate.confidence
                    )
                )
            }
        }

        return result
    }
}

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
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
