import Foundation
import CoreGraphics
import SwiftUI

enum LogoStyle: String, Codable {
    case photo
    case emoji
    case symbol
}

enum SymbolRendering: String, Codable, CaseIterable {
    case solid
    case multicolor
    case gradient
}

struct LogoCustomization: Identifiable, Codable, Equatable {
    var id: UUID

    var primaryColorHex: String
    var secondaryColorHex: String?
    var shadowColorHex: String?
    var backgroundColorHex: String?

    var style: LogoStyle
    var emoji: String?
    var symbolName: String?
    var symbolRendering: SymbolRendering = .solid
    var imageData: Data?
    var imageOffsetX: CGFloat
    var imageOffsetY: CGFloat
    var imageScale: CGFloat

    init(
        id: UUID,
        primaryColorHex: String = "#F6F6F5",
        secondaryColorHex: String? = nil,
        shadowColorHex: String? = nil,
        backgroundColorHex: String? = nil,
        style: LogoStyle = .symbol,
        emoji: String? = nil,
        symbolName: String? = "creditcard.fill",
        symbolRendering: SymbolRendering = .solid,
        imageData: Data? = nil,
        imageOffsetX: CGFloat = 0,
        imageOffsetY: CGFloat = 0,
        imageScale: CGFloat = 1.0
    ) {
        self.id = id
        self.primaryColorHex = primaryColorHex
        self.secondaryColorHex = secondaryColorHex
        self.shadowColorHex = shadowColorHex
        self.backgroundColorHex = backgroundColorHex
        self.style = style
        self.emoji = emoji
        self.symbolName = symbolName
        self.symbolRendering = symbolRendering
        self.imageData = imageData
        self.imageOffsetX = imageOffsetX
        self.imageOffsetY = imageOffsetY
        self.imageScale = imageScale
    }

    var primaryColor: Color { Color(hex: primaryColorHex) }
    var secondaryColor: Color? { secondaryColorHex.map { Color(hex: $0) } }
    var shadowColor: Color? { shadowColorHex.map { Color(hex: $0) } }
    var backgroundColor: Color? { backgroundColorHex.map { Color(hex: $0) } }

    var resolvedForeground: Color { secondaryColor ?? .black }
    var resolvedBackground: Color { backgroundColor ?? primaryColor }
    var resolvedShadow: Color { shadowColor ?? secondaryColor ?? primaryColor }
}
