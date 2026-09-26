#if FF_VISUAL_INTELLIGENCE
import AppIntents
import CoreImage
import SwiftUI

/// A receipt Visual Intelligence found items on, offered as a Satoru result
/// ("Add 3 items · $12.70"). Opening it shows the usual receipt review.
struct ReceiptCaptureEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Receipt"
    static let defaultQuery = ReceiptCaptureQuery()

    let id: UUID
    let items: [ScannedExpenseItem]
    let summary: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "Add \(items.count) \(items.count == 1 ? "item" : "items") to Satoru",
            subtitle: "\(summary)",
            image: .init(systemName: "receipt")
        )
    }
}

struct ReceiptCaptureQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [ReceiptCaptureEntity] {
        identifiers.compactMap { ReceiptCaptureCache.entries[$0] }
    }
}

/// Results live only in memory between Visual Intelligence showing them and
/// the user tapping one.
/// ponytail: lost if the app is killed in between; persist to the App Group
/// if that turns out to matter.
@MainActor
enum ReceiptCaptureCache {
    static var entries: [UUID: ReceiptCaptureEntity] = [:]

    static func add(_ items: [ScannedExpenseItem], settings: AppSettings) -> ReceiptCaptureEntity {
        let total = items.reduce(0) { $0 + $1.price }
        let entity = ReceiptCaptureEntity(
            id: UUID(),
            items: items,
            summary: "\(items.map(\.name).prefix(3).joined(separator: ", ")) · \(MoneyFormatter.format(total, settings: settings))"
        )
        entries[entity.id] = entity
        return entity
    }

    /// OCR + smart parsing, shared by Visual Intelligence and the DEBUG hook.
    static func capture(_ cgImage: CGImage, settings: AppSettings) async throws -> ReceiptCaptureEntity? {
        let tokens = try await ReceiptOCRService.recognizeTokens(in: cgImage, orientation: .up)
        let items = await ReceiptSmartParser.items(from: tokens, categories: settings.categories.map(\.name))
        return items.isEmpty ? nil : add(items, settings: settings)
    }
}

struct OpenReceiptCaptureIntent: OpenIntent {
    static let title: LocalizedStringResource = "Review Receipt"

    @Parameter(title: "Receipt")
    var target: ReceiptCaptureEntity

    @Dependency private var router: IntentRouter

    @MainActor
    func perform() async throws -> some IntentResult {
        router.pendingReceiptID = target.id
        return .result()
    }
}

extension View {
    /// Presents the review for a receipt opened from Visual Intelligence.
    func receiptCaptureSheet(router: IntentRouter, store: AppStore, settingsStore: SettingsStore) -> some View {
        sheet(item: Binding(
            get: { router.pendingReceiptID.flatMap { ReceiptCaptureCache.entries[$0] } },
            set: { if $0 == nil { router.pendingReceiptID = nil } }
        )) { capture in
            ReceiptScanSheet(date: Calendar.current.startOfDay(for: .now), store: store,
                             settingsStore: settingsStore, items: capture.items) {
                ReceiptCaptureCache.entries[capture.id] = nil
                router.pendingReceiptID = nil
            }
        }
    }
}

#if canImport(VisualIntelligence)
import VisualIntelligence

/// Visual Intelligence (camera or screenshot) asks Satoru for results on
/// what the user is looking at. Answers only when the image reads as a
/// receipt with items, so Satoru stays out of unrelated searches.
struct ReceiptVisualQuery: IntentValueQuery {
    @Dependency private var settingsStore: SettingsStore

    @MainActor
    func values(for input: SemanticContentDescriptor) async throws -> [ReceiptCaptureEntity] {
        guard let buffer = input.pixelBuffer,
              let cgImage = buffer.withUnsafeBuffer({ pixelBuffer -> CGImage? in
                  let image = CIImage(cvPixelBuffer: pixelBuffer)
                  return CIContext().createCGImage(image, from: image.extent)
              })
        else { return [] }
        return try await ReceiptCaptureCache.capture(cgImage, settings: settingsStore.settings).map { [$0] } ?? []
    }
}
#endif

#if DEBUG
extension ReceiptCaptureCache {
    /// `SIMCTL_CHILD_DEBUG_SCAN_SAMPLE=1`: runs a rendered receipt through the
    /// same capture path Visual Intelligence uses (its SDK is device-only).
    static func debugSample(settings: AppSettings) async -> UUID? {
        let lines: [(String, String?)] = [
            ("CORNER CAFE", nil), ("Latte", "5.50"), ("Sesame Bagel", "3.20"),
            ("Orange Juice", "4.00"), ("TAX", "1.65"), ("TOTAL", "14.35"),
        ]
        let size = CGSize(width: 600, height: 60 + lines.count * 44)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 26, weight: .medium),
                .foregroundColor: UIColor.black,
            ]
            for (index, line) in lines.enumerated() {
                let y = CGFloat(30 + index * 44)
                line.0.draw(at: CGPoint(x: 30, y: y), withAttributes: attributes)
                if let right = line.1 {
                    let width = (right as NSString).size(withAttributes: attributes).width
                    right.draw(at: CGPoint(x: size.width - 30 - width, y: y), withAttributes: attributes)
                }
            }
        }
        guard let cgImage = image.cgImage else { return nil }
        return try? await capture(cgImage, settings: settings)?.id
    }
}
#endif
#endif
