import Foundation

enum MoneyFormatter {

    private static let symbols: [String: String] = [
        "CAD": "$", "USD": "$", "EUR": "€",
        "BRL": "R$", "GBP": "£", "JPY": "¥",
    ]

    static func symbol(for code: String) -> String {
        symbols[code] ?? code
    }

    /// Formats a monetary value according to the current app settings.
    /// - Parameters:
    ///   - value: The raw numeric value.
    ///   - settings: The current `AppSettings`.
    ///   - currencyCode: Optional override; falls back to `settings.currencyCode`.
    static func format(_ value: Double, settings: AppSettings, currencyCode: String? = nil) -> String {
        let code = currencyCode ?? settings.currencyCode
        let sym = symbol(for: code)
        return sym + formatNumber(value, round: settings.roundAmounts, abbreviate: settings.abbreviateLargeNumbers)
    }

    /// Formats just the numeric part (no currency symbol).
    static func formatNumber(_ value: Double, round: Bool, abbreviate: Bool) -> String {
        if abbreviate {
            let (divided, suffix) = abbreviationComponents(for: value)
            if !suffix.isEmpty {
                // Large number: use one decimal unless rounding is on
                if round {
                    return "\(Int(divided.rounded()))\(suffix)"
                } else {
                    let formatted = String(format: "%.1f", divided)
                    let cleaned = formatted.hasSuffix(".0") ? String(formatted.dropLast(2)) : formatted
                    return "\(cleaned)\(suffix)"
                }
            }
        }
        // Normal path
        return value.formatted(
            .number
                .precision(.fractionLength(round ? 0 : 2))
                .locale(Locale(identifier: "en_US"))
        )
    }

    private static func abbreviationComponents(for value: Double) -> (Double, String) {
        let abs = Swift.abs(value)
        if abs >= 1_000_000_000 { return (value / 1_000_000_000, "B") }
        if abs >= 1_000_000     { return (value / 1_000_000,     "M") }
        if abs >= 1_000         { return (value / 1_000,         "k") }
        return (value, "")
    }
}
