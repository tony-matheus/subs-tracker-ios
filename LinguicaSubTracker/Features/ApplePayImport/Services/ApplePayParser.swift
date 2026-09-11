import Foundation

enum ApplePayParser {

    /// Parses raw text input (which can be notification text, structured CSV statement, or JSON payload),
    /// taking into account the user's selected currencyCode (e.g. "BRL", "USD", "EUR", "CAD").
    static func parseRawText(
        _ text: String,
        availableCategories: [String],
        currencyCode: String = "BRL"
    ) -> [ApplePayTransaction] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        // Check if input is JSON
        if trimmed.hasPrefix("[") || trimmed.hasPrefix("{") {
            if let transactions = parseJSON(trimmed, availableCategories: availableCategories), !transactions.isEmpty {
                return transactions
            }
        }

        let lines = trimmed.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else { return [] }

        // 1. Try parsing as a structured CSV document first (with header detection & mapped columns)
        let csvResults = parseCSVDocument(lines, availableCategories: availableCategories, currencyCode: currencyCode)
        if !csvResults.isEmpty {
            return csvResults
        }

        // 2. Fallback to line-by-line parsing for freeform notification text
        var results: [ApplePayTransaction] = []
        for line in lines {
            if let transaction = parseSingleLine(line, availableCategories: availableCategories, currencyCode: currencyCode) {
                results.append(transaction)
            }
        }

        return results
    }

    /// Parses a structured CSV document with column header index mapping & quoted field support.
    private static func parseCSVDocument(
        _ lines: [String],
        availableCategories: [String],
        currencyCode: String
    ) -> [ApplePayTransaction] {
        // Detect delimiter (comma, semicolon, or tab)
        let sampleLine = lines.first { $0.contains(",") || $0.contains(";") || $0.contains("\t") }
        guard let firstSeparated = sampleLine else { return [] }
        let delimiter: Character = firstSeparated.contains(";") ? ";" : (firstSeparated.contains("\t") ? "\t" : ",")

        var dateIdx: Int? = nil
        var titleIdx: Int? = nil
        var amountIdx: Int? = nil

        var startIndex = 0

        // Inspect first line for CSV headers
        let firstRowParts = splitCSVLine(lines[0], delimiter: delimiter)
        let lowerFirstParts = firstRowParts.map { $0.lowercased().trimmingCharacters(in: .punctuationCharacters) }

        for (idx, header) in lowerFirstParts.enumerated() {
            if ["date", "data", "dia", "clearing date", "transacted date"].contains(header) {
                dateIdx = idx
            } else if ["title", "merchant", "description", "estabelecimento", "historico", "descrição", "comerciante", "memo"].contains(header) {
                titleIdx = idx
            } else if ["amount", "valor", "price", "quantia", "total"].contains(header) {
                amountIdx = idx
            }
        }

        if dateIdx != nil || titleIdx != nil || amountIdx != nil {
            // First line was indeed a header row!
            startIndex = 1
        }

        var transactions: [ApplePayTransaction] = []

        for i in startIndex..<lines.count {
            let line = lines[i]
            let parts = splitCSVLine(line, delimiter: delimiter)
            guard parts.count >= 2 else { continue }

            var parsedDate: Date? = nil
            var parsedMerchant: String? = nil
            var parsedAmount: Double? = nil

            // Explicit column extraction if header indices were identified:
            if let dIdx = dateIdx, dIdx < parts.count {
                parsedDate = parseDate(from: parts[dIdx])
            }
            if let tIdx = titleIdx, tIdx < parts.count {
                let cleaned = cleanMerchantTitle(parts[tIdx])
                if !cleaned.isEmpty { parsedMerchant = cleaned }
            }
            if let aIdx = amountIdx, aIdx < parts.count {
                parsedAmount = parsePureAmount(parts[aIdx], currencyCode: currencyCode)
            }

            // Heuristic fallbacks for unmapped columns or headerless CSVs:
            if parsedAmount == nil || parsedMerchant == nil {
                for part in parts {
                    let cleanPart = part.trimmingCharacters(in: .whitespaces)
                    if cleanPart.isEmpty { continue }

                    if parsedDate == nil && isDateString(cleanPart) {
                        parsedDate = parseDate(from: cleanPart)
                    } else if parsedAmount == nil && isPureAmountString(cleanPart) {
                        parsedAmount = parsePureAmount(cleanPart, currencyCode: currencyCode)
                    } else if parsedMerchant == nil && hasAlphanumericText(cleanPart) && !isDateString(cleanPart) && !isPureAmountString(cleanPart) {
                        parsedMerchant = cleanMerchantTitle(cleanPart)
                    }
                }
            }

            guard let amount = parsedAmount, amount > 0 else { continue }

            let merchant = (parsedMerchant?.isEmpty == false) ? parsedMerchant! : "Apple Pay Purchase"
            let date = parsedDate ?? Date()
            let category = ApplePayCategorizer.categorize(merchant: merchant, availableCategories: availableCategories)

            transactions.append(
                ApplePayTransaction(
                    merchant: merchant,
                    amount: amount,
                    date: date,
                    category: category,
                    paymentMethod: "Apple Pay",
                    notes: "Imported via CSV statement"
                )
            )
        }

        return transactions
    }

    /// Splits a CSV line while correctly handling quoted fields like `"90,56"` or `"Sqsp* Domain#2498"`.
    private static func splitCSVLine(_ line: String, delimiter: Character) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == delimiter && !inQuotes {
                result.append(current.trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: "\""))))
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current.trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: "\""))))
        return result
    }

    /// Checks if a field contains letters (meaning it's description/merchant, not numeric amount/date).
    private static func hasAlphanumericText(_ str: String) -> Bool {
        return str.rangeOfCharacter(from: CharacterSet.letters) != nil
    }

    /// Checks if a string represents a pure numeric monetary amount (no letters, e.g. "90,56", "-45.90", "R$ 90,56").
    private static func isPureAmountString(_ str: String) -> Bool {
        let clean = str.trimmingCharacters(in: .whitespaces)
        if isDateString(clean) { return false }
        if hasAlphanumericText(clean) && !clean.localizedCaseInsensitiveContains("R$") {
            return false
        }
        return extractAmount(from: clean) != nil
    }

    /// Direct parser for a CSV field known to contain the amount (e.g. "90,56" or "-45.90" or "R$ 90,56").
    private static func parsePureAmount(_ str: String, currencyCode: String) -> Double? {
        let clean = str.trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: "\"$R$€£¥")))
        if clean.isEmpty { return nil }

        var valStr = clean
            .replacingOccurrences(of: "R$", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "£", with: "")
            .replacingOccurrences(of: "¥", with: "")
            .trimmingCharacters(in: .whitespaces)

        let isCommaDecimal = (currencyCode == "BRL" || currencyCode == "EUR")

        if isCommaDecimal {
            // "90,56" -> "90.56", "1.250,50" -> "1250.50"
            if valStr.contains(",") && valStr.contains(".") {
                valStr = valStr.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            } else if valStr.contains(",") {
                valStr = valStr.replacingOccurrences(of: ",", with: ".")
            } else if valStr.contains(".") {
                let parts = valStr.split(separator: ".")
                if parts.count == 2 && parts[1].count == 3 {
                    valStr = valStr.replacingOccurrences(of: ".", with: "")
                }
            }
        } else {
            // "90.56" -> "90.56", "1,250.50" -> "1250.50"
            if valStr.contains(",") && valStr.contains(".") {
                valStr = valStr.replacingOccurrences(of: ",", with: "")
            } else if valStr.contains(",") {
                let parts = valStr.split(separator: ",")
                if parts.count == 2 && parts[1].count == 3 {
                    valStr = valStr.replacingOccurrences(of: ",", with: "")
                } else {
                    valStr = valStr.replacingOccurrences(of: ",", with: ".")
                }
            }
        }

        if let val = Double(valStr) {
            return abs(val)
        }
        return nil
    }

    /// Parses a single line of natural language notification text.
    static func parseSingleLine(
        _ line: String,
        availableCategories: [String],
        currencyCode: String = "BRL"
    ) -> ApplePayTransaction? {
        guard let (amount, amountRange) = extractAmount(from: line, currencyCode: currencyCode) else {
            return nil
        }

        var merchantPart = line
        if let range = Range(amountRange, in: line) {
            merchantPart.removeSubrange(range)
        }

        let datePattern = #"\b\d{1,4}[-/\.]\d{1,2}[-/\.]\d{1,4}\b"#
        if let dateRegex = try? NSRegularExpression(pattern: datePattern) {
            merchantPart = dateRegex.stringByReplacingMatches(
                in: merchantPart,
                range: NSRange(location: 0, length: merchantPart.utf16.count),
                withTemplate: " "
            )
        }

        let noiseRegexes = [
            "(?i)apple pay",
            "(?i)cartão",
            "(?i)card",
            "(?i)pago",
            "(?i)pagamento",
            "(?i)compra",
            "(?i)aprovada",
            "(?i)r\\$",
            "\\$",
            "€",
            "£",
            "¥",
            "(?i)\\bem\\b",
            "(?i)\\bna\\b",
            "(?i)\\bno\\b",
            "(?i)\\bpara\\b",
            "(?i)\\bat\\b",
            "(?i)\\bfrom\\b"
        ]

        for pattern in noiseRegexes {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                merchantPart = regex.stringByReplacingMatches(
                    in: merchantPart,
                    range: NSRange(location: 0, length: merchantPart.utf16.count),
                    withTemplate: " "
                )
            }
        }

        let cleanMerchantName = cleanMerchantTitle(merchantPart)
        let finalMerchant = cleanMerchantName.isEmpty ? "Apple Pay Purchase" : cleanMerchantName

        let category = ApplePayCategorizer.categorize(merchant: finalMerchant, availableCategories: availableCategories)

        return ApplePayTransaction(
            merchant: finalMerchant,
            amount: amount,
            date: Date(),
            category: category,
            paymentMethod: "Apple Pay",
            notes: "Imported from notification text"
        )
    }

    /// Cleans raw merchant title by removing payment prefixes like PAG*, EBN*, IFD*, MP*, and order numbers like #249876522.
    private static func cleanMerchantTitle(_ raw: String) -> String {
        var name = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove wildcard stars like Sqsp* Domain -> Sqsp Domain
        name = name.replacingOccurrences(of: "*", with: " ")

        // Remove order hashes like #249876522
        if let hashRegex = try? NSRegularExpression(pattern: "(?i)#\\d+") {
            name = hashRegex.stringByReplacingMatches(
                in: name,
                range: NSRange(location: 0, length: name.utf16.count),
                withTemplate: ""
            )
        }

        // Common Brazilian & international bank transaction prefixes
        let prefixRegexes = [
            "^(?i)PAG\\s*",
            "^(?i)PG\\s*",
            "^(?i)EBN\\s*",
            "^(?i)MP\\s*",
            "^(?i)IFD\\s*",
            "^(?i)DL\\s*",
            "^(?i)PAYPAL\\s*",
            "^(?i)COMPRA\\s+COM\\s+CARTAO\\s*-?\\s*",
            "^(?i)COMPRA\\s+APROVADA\\s*-?\\s*"
        ]

        for pattern in prefixRegexes {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                name = regex.stringByReplacingMatches(
                    in: name,
                    range: NSRange(location: 0, length: name.utf16.count),
                    withTemplate: ""
                )
            }
        }

        // Clean extra non-alphanumeric noise at edges
        let trimmed = name
            .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet.whitespaces).inverted)
            .joined(separator: " ")
            .split(separator: " ")
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return trimmed.capitalized
    }

    /// Checks whether a string is formatted as a date (e.g. 2026-09-10, 10/09/2026).
    private static func isDateString(_ str: String) -> Bool {
        let datePattern = #"^\d{1,4}[-/\.]\d{1,2}[-/\.]\d{1,4}(?:\s+\d{1,2}:\d{2}(?::\d{2})?)?$"#
        return str.range(of: datePattern, options: .regularExpression) != nil
    }

    /// Attempts to parse a Date from strings like "2026-09-10", "10/09/2026", "10/09/26".
    private static func parseDate(from text: String) -> Date? {
        let formats = [
            "yyyy-MM-dd",
            "dd/MM/yyyy",
            "dd-MM-yyyy",
            "dd.MM.yyyy",
            "yyyy/MM/dd",
            "dd/MM/yy",
            "yyyy-MM-dd'T'HH:mm:ss"
        ]

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let cleanText = text.trimmingCharacters(in: .whitespaces)

        for fmt in formats {
            formatter.dateFormat = fmt
            if let date = formatter.date(from: cleanText) {
                return date
            }
        }
        return nil
    }

    /// Helper to find monetary float/double values in strings, respecting `currencyCode`.
    private static func extractAmount(
        from text: String,
        currencyCode: String = "BRL"
    ) -> (Double, NSRange)? {
        let cleanText = text.trimmingCharacters(in: .whitespaces)

        if isDateString(cleanText) {
            return nil
        }

        let hasExplicitR$ = cleanText.contains("R$") || cleanText.localizedCaseInsensitiveContains("BRL")
        let hasExplicitDollar = cleanText.contains("$") && !hasExplicitR$
        let hasExplicitEuro = cleanText.contains("€") || cleanText.localizedCaseInsensitiveContains("EUR")

        let pattern = #"(?:R\$\s*|\$\s*|€\s*|£\s*|¥\s*|-)?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        let range = NSRange(cleanText.startIndex..., in: cleanText)
        let matches = regex.matches(in: cleanText, range: range)

        let isCommaDecimal: Bool
        if hasExplicitR$ || hasExplicitEuro {
            isCommaDecimal = true
        } else if hasExplicitDollar {
            isCommaDecimal = false
        } else {
            isCommaDecimal = (currencyCode == "BRL" || currencyCode == "EUR")
        }

        for match in matches {
            if match.numberOfRanges > 1, let matchRange = Range(match.range(at: 1), in: cleanText) {
                var valStr = String(cleanText[matchRange])

                if isCommaDecimal {
                    if valStr.contains(",") && valStr.contains(".") {
                        valStr = valStr.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
                    } else if valStr.contains(",") {
                        valStr = valStr.replacingOccurrences(of: ",", with: ".")
                    } else if valStr.contains(".") {
                        let parts = valStr.split(separator: ".")
                        if parts.count == 2 && parts[1].count == 3 {
                            valStr = valStr.replacingOccurrences(of: ".", with: "")
                        }
                    }
                } else {
                    if valStr.contains(",") && valStr.contains(".") {
                        valStr = valStr.replacingOccurrences(of: ",", with: "")
                    } else if valStr.contains(",") {
                        let parts = valStr.split(separator: ",")
                        if parts.count == 2 && parts[1].count == 3 {
                            valStr = valStr.replacingOccurrences(of: ",", with: "")
                        } else {
                            valStr = valStr.replacingOccurrences(of: ",", with: ".")
                        }
                    }
                }

                if let val = Double(valStr), val > 0 {
                    return (abs(val), match.range)
                }
            }
        }

        return nil
    }

    private static func parseJSON(_ jsonString: String, availableCategories: [String]) -> [ApplePayTransaction]? {
        guard let data = jsonString.data(using: .utf8) else { return nil }

        struct RawPayload: Codable {
            let merchant: String?
            let name: String?
            let amount: Double?
            let price: Double?
            let category: String?
        }

        if let list = try? JSONDecoder().decode([RawPayload].self, from: data) {
            return list.compactMap { item in
                let m = item.merchant ?? item.name ?? "Apple Pay Purchase"
                let a = item.amount ?? item.price ?? 0.0
                guard a > 0 else { return nil }
                let cat = item.category ?? ApplePayCategorizer.categorize(merchant: m, availableCategories: availableCategories)
                return ApplePayTransaction(
                    merchant: m,
                    amount: abs(a),
                    date: Date(),
                    category: cat,
                    paymentMethod: "Apple Pay"
                )
            }
        }

        return nil
    }
}
