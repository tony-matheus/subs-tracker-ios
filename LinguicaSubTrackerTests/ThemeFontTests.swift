import CoreText
import Testing
import UIKit
@testable import LinguicaSubTracker

@Suite("Theme fonts")
struct ThemeFontTests {
    @Test("Fragment Mono is registered and covers the app's currencies")
    func fragmentMono() throws {
        #expect(Theme.FontName.regular.rawValue == AppFont.mono)
        let font = try #require(UIFont(name: AppFont.mono, size: 15)) as CTFont
        for symbol in ["$", "€", "R", "£", "¥"] {
            let chars = Array(symbol.utf16)
            var glyphs = [CGGlyph](repeating: 0, count: chars.count)
            #expect(CTFontGetGlyphsForCharacters(font, chars, &glyphs, chars.count), "missing \(symbol)")
        }
        #expect(UIFont(name: "FragmentMono-Italic", size: 15) != nil)
    }

    @Test func kanjiFontsExist() {
        #expect(UIFont(name: AppFont.kanji, size: 13) != nil)
        #expect(UIFont(name: AppFont.kanjiBold, size: 13) != nil)
    }
}
