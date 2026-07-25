import Foundation
import FoundationModels

/// Turns a spoken transcript into reviewable expenses. Uses on-device
/// FoundationModels guided generation when the hardware supports it,
/// otherwise a deterministic regex fallback.
enum VoiceExpenseParser {

    static func parse(transcript: String, categories: [String]) async -> [ParsedExpense] {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        if case .available = SystemLanguageModel.default.availability {
            do {
                let items = try await aiParse(trimmed, categories: categories)
                if !items.isEmpty { return items }
            } catch {
                // Model hiccup → deterministic path below.
            }
        }
        return regexParse(trimmed, categories: categories)
    }

    // MARK: - AI path

    private static func aiParse(_ transcript: String, categories: [String]) async throws -> [ParsedExpense] {
        let session = LanguageModelSession(instructions: """
            Extract every expense the user mentions in their spoken sentence.
            Each expense has a merchant/description name, an amount, how many \
            days ago it happened (0 = today, 1 = yesterday), and a category.
            The category MUST be exactly one of: \(categories.joined(separator: ", ")). \
            If none clearly fits, use "Other".
            """)
        let response = try await session.respond(
            to: transcript,
            generating: GeneratedExpenses.self
        )
        return response.content.expenses.compactMap { generated in
            let name = generated.name.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty, generated.amount > 0 else { return nil }
            return ParsedExpense(
                name: name,
                amount: generated.amount,
                daysAgo: max(0, generated.daysAgo),
                category: snapCategory(generated.category, to: categories)
            )
        }
    }

    // MARK: - Category snapping

    /// Best case-insensitive match against existing category names; "Other"
    /// (or the last category) when nothing matches. Never invents a category.
    static func snapCategory(_ raw: String?, to categories: [String]) -> String {
        let fallback = categories.first { $0.caseInsensitiveCompare("Other") == .orderedSame }
            ?? categories.last ?? "Other"
        guard let raw = raw?.trimmingCharacters(in: .whitespaces).lowercased(),
              !raw.isEmpty else { return fallback }

        if let exact = categories.first(where: { $0.lowercased() == raw }) { return exact }
        if let partial = categories.first(where: {
            $0.lowercased().contains(raw) || raw.contains($0.lowercased())
        }) { return partial }
        return fallback
    }

    // MARK: - Regex fallback

    /// Deterministic parser for "50 dollars on Safeway", "yesterday I spent
    /// twenty at Starbucks and 12.50 on lunch".
    /// ponytail: handles digits + number words 0-999 and today/yesterday/weekday
    /// dates; upgrade to the AI path is automatic on eligible hardware.
    static func regexParse(_ transcript: String, categories: [String]) -> [ParsedExpense] {
        // First split on explicit connectors (comma / "and" / "then"), then
        // split each piece before every *subsequent* money-amount. Dictation
        // drops the commas people say in their head, so a fresh amount is the
        // real "next item" signal — but a lead-in ("yesterday I spent 20…")
        // must stay attached to its amount, so the first amount never splits.
        let segments = transcript
            .replacingOccurrences(of: #"(?i)\s*,\s*(?:and\s+)?|\s+and\s+|\s+then\s+"#,
                                  with: "\n",
                                  options: .regularExpression)
            .components(separatedBy: "\n")
            .flatMap(splitOnAmounts)
        return segments.compactMap { parseSegment($0, categories: categories) }
    }

    /// A number counts as a new amount only when it carries a money cue —
    /// currency word, merchant preposition, or a leading "$" — so "7 eleven"
    /// or "2 coffees" don't false-split.
    private static let amountCue =
        #"(?i)\$\d[\d.,]*|\d[\d.,]*\s+(?:dollars?|bucks?|cents?|euros?|euro|pounds?|pound|on|at|for|from|in)\b"#

    /// Breaks a line before each money-amount after the first, keeping any
    /// lead-in (dates, "I spent") with the first amount.
    private static func splitOnAmounts(_ line: String) -> [String] {
        var starts: [String.Index] = []
        var searchStart = line.startIndex
        while let range = line.range(
            of: amountCue, options: .regularExpression, range: searchStart..<line.endIndex
        ) {
            starts.append(range.lowerBound)
            searchStart = range.upperBound
        }
        guard starts.count > 1 else { return [line] }

        var segments: [String] = []
        var prev = line.startIndex
        for boundary in starts.dropFirst() {
            segments.append(String(line[prev..<boundary]))
            prev = boundary
        }
        segments.append(String(line[prev..<line.endIndex]))
        return segments
    }

    private static func parseSegment(_ raw: String, categories: [String]) -> ParsedExpense? {
        var text = raw.lowercased().trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }

        guard let amount = extractAmount(&text), amount > 0 else { return nil }
        let daysAgo = extractDaysAgo(&text)
        let name = extractName(from: text)
        guard !name.isEmpty else { return nil }

        return ParsedExpense(
            name: name,
            amount: amount,
            daysAgo: daysAgo,
            category: snapCategory(name, to: categories)
        )
    }

    /// Pulls the first digit amount ("$50", "12.50") or number-word run
    /// ("fifty", "twenty five") out of `text`, removing it in place.
    private static func extractAmount(_ text: inout String) -> Double? {
        // Digits first — dictation usually renders "fifty dollars" as "$50".
        if let range = text.range(
            of: #"\$?\d{1,6}(?:[.,]\d{1,2})?"#,
            options: .regularExpression
        ) {
            let token = text[range]
                .replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: ",", with: ".")
            text.removeSubrange(range)
            return Double(token)
        }
        return extractNumberWords(&text)
    }

    private static let onesWords: [String: Int] = [
        "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6,
        "seven": 7, "eight": 8, "nine": 9, "ten": 10, "eleven": 11,
        "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15,
        "sixteen": 16, "seventeen": 17, "eighteen": 18, "nineteen": 19,
    ]
    private static let tensWords: [String: Int] = [
        "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50,
        "sixty": 60, "seventy": 70, "eighty": 80, "ninety": 90,
    ]

    /// Consumes a contiguous run of number words ("one hundred twenty five")
    /// from `text`. ponytail: 0-999 only; thousands unlikely in spoken spends.
    private static func extractNumberWords(_ text: inout String) -> Double? {
        let words = text.split(separator: " ").map(String.init)
        var value = 0
        var current = 0
        var startIndex: Int?
        var endIndex: Int?

        for (index, word) in words.enumerated() {
            let isNumberWord: Bool
            if let n = onesWords[word] ?? tensWords[word] {
                current += n
                isNumberWord = true
            } else if word == "hundred" {
                current = max(current, 1) * 100
                isNumberWord = true
            } else {
                isNumberWord = false
            }

            if isNumberWord {
                if startIndex == nil { startIndex = index }
                endIndex = index
            } else if startIndex != nil {
                break // only the first number run
            }
        }
        value = current

        guard let start = startIndex, let end = endIndex, value > 0 else { return nil }
        let kept = words[..<start] + words[(end + 1)...]
        text = kept.joined(separator: " ")
        return Double(value)
    }

    /// Finds a relative-date word (today / yesterday / weekday name),
    /// removes it, and returns the day offset.
    private static func extractDaysAgo(_ text: inout String) -> Int {
        if let range = text.range(of: #"last night|yesterday"#, options: .regularExpression) {
            text.removeSubrange(range)
            return 1
        }
        if let range = text.range(of: "today") {
            text.removeSubrange(range)
            return 0
        }
        let weekdays = Calendar.current.weekdaySymbols.map { $0.lowercased() }
        for (index, day) in weekdays.enumerated() {
            guard let range = text.range(of: day) else { continue }
            text.removeSubrange(range)
            let today = Calendar.current.component(.weekday, from: .now) - 1
            return (today - index + 7) % 7
        }
        return 0
    }

    private static let stopWords: Set<String> = [
        "i", "spent", "paid", "bought", "got", "dollars", "dollar", "bucks",
        "euros", "euro", "pounds", "cents", "me", "a", "an", "the", "some",
        "about", "around", "of", "it", "was", "worth",
    ]

    /// Merchant name: text after "on/at/for/from" when present, otherwise
    /// whatever survives stop-word removal.
    private static func extractName(from text: String) -> String {
        var candidate = text
        if let match = text.range(
            of: #"(?:^|\s)(?:on|at|for|from|in)\s+(.+)$"#,
            options: .regularExpression
        ) {
            candidate = String(text[match])
                .replacingOccurrences(of: #"^\s*(?:on|at|for|from|in)\s+"#,
                                      with: "",
                                      options: .regularExpression)
        }
        let words = candidate
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && !stopWords.contains($0) && !["on", "at", "for", "from", "in"].contains($0) }
        return words.joined(separator: " ").capitalized
    }
}
