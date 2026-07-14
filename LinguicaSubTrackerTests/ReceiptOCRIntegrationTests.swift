import Testing
import UIKit

@testable import LinguicaSubTracker

/// End-to-end pipeline check: renders a receipt as an image, runs the real
/// Vision OCR pass, and parses items out of the recognized tokens.
struct ReceiptOCRIntegrationTests {

    private func renderReceipt(lines: [(left: String, right: String?)]) -> UIImage {
        let size = CGSize(width: 600, height: 60 + lines.count * 44)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let font = UIFont.monospacedSystemFont(ofSize: 26, weight: .medium)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black,
            ]

            for (index, line) in lines.enumerated() {
                let y = CGFloat(30 + index * 44)
                line.left.draw(at: CGPoint(x: 30, y: y), withAttributes: attributes)
                if let right = line.right {
                    let width = (right as NSString).size(withAttributes: attributes).width
                    right.draw(at: CGPoint(x: size.width - 30 - width, y: y), withAttributes: attributes)
                }
            }
        }
    }

    @Test func fullPipelineExtractsItemsFromRenderedReceipt() async throws {
        let image = renderReceipt(lines: [
            ("CORNER CAFE", nil),
            ("123 Main Street", nil),
            ("Latte", "5.50"),
            ("Sesame Bagel", "3.20"),
            ("Orange Juice", "4.00"),
            ("SUBTOTAL", "12.70"),
            ("TAX", "1.65"),
            ("TOTAL", "14.35"),
        ])

        let tokens = try await ReceiptOCRService.recognizeTokens(in: image)
        #expect(!tokens.isEmpty)

        let items = ReceiptParser.items(from: tokens)

        #expect(items.count == 3)
        #expect(items.contains { $0.name.localizedCaseInsensitiveContains("Latte") && $0.price == 5.50 })
        #expect(items.contains { $0.name.localizedCaseInsensitiveContains("Bagel") && $0.price == 3.20 })
        #expect(items.contains { $0.name.localizedCaseInsensitiveContains("Juice") && $0.price == 4.00 })
        #expect(!items.contains { $0.name.localizedCaseInsensitiveContains("total") })
    }
}
