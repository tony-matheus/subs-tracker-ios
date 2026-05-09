import Foundation
import CoreGraphics

enum LogoStyle: String, Codable {
    case photo
    case emoji
    case symbol
}

struct LogoCustomization: Identifiable, Codable, Equatable {
    var id: UUID
    var style: LogoStyle
    var colorHex: String
    var emoji: String?
    var symbolName: String?
    var imageData: Data?
    var imageOffsetX: CGFloat
    var imageOffsetY: CGFloat
    var imageScale: CGFloat

    init(
        id: UUID,
        style: LogoStyle = .symbol,
        colorHex: String = LogoPalette.colors[0],
        emoji: String? = nil,
        symbolName: String? = "creditcard.fill",
        imageData: Data? = nil,
        imageOffsetX: CGFloat = 0,
        imageOffsetY: CGFloat = 0,
        imageScale: CGFloat = 1.0
    ) {
        self.id = id
        self.style = style
        self.colorHex = colorHex
        self.emoji = emoji
        self.symbolName = symbolName
        self.imageData = imageData
        self.imageOffsetX = imageOffsetX
        self.imageOffsetY = imageOffsetY
        self.imageScale = imageScale
    }
}
