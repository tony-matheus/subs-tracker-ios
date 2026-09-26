import Foundation
import Testing

@testable import LinguicaSubTracker

@Suite("Speech locale choice")
struct SpeechLocaleTests {
    let supported = [Locale(identifier: "en-US"), Locale(identifier: "en-GB"), Locale(identifier: "pt-BR")]

    @Test("exact match wins")
    func exact() {
        #expect(SpeechTranscriptionService.pickLocale(Locale(identifier: "en-GB"), from: supported)?
            .identifier(.bcp47) == "en-GB")
    }

    @Test("falls back to the same language")
    func sameLanguage() {
        #expect(SpeechTranscriptionService.pickLocale(Locale(identifier: "en-CA"), from: supported)?
            .language.languageCode == .english)
    }

    @Test("unsupported language gives nil")
    func unsupported() {
        #expect(SpeechTranscriptionService.pickLocale(Locale(identifier: "ja-JP"), from: supported) == nil)
    }
}
