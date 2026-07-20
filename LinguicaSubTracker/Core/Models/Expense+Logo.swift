import Foundation

extension LogoCustomization {
    /// Single source of truth for resolving an expense's logo customization.
    ///
    /// Resolution order:
    /// 1. User-saved override in `AppStore.logoCustomizations`.
    /// 2. Template defaults via `SubscriptionTemplate.template(matching:)`
    ///    (matches the look used by the popular-expenses picker).
    /// 3. Neutral gray fallback for unrecognized names.
    static func resolved(
        for id: UUID,
        name: String,
        in store: AppStore
    ) -> LogoCustomization {
        if let saved = store.customization(for: id) { return saved }
        if let template = SubscriptionTemplate.template(matching: name) {
            return template.makeCustomization(id: id)
        }
        // Unknown name → "random" color + symbol, seeded by the name so a
        // merchant keeps the same look across renders and sessions.
        let seed = stableHash(
            name.lowercased().trimmingCharacters(in: .whitespaces)
        )
        return LogoCustomization(
            id: id,
            primaryColorHex: fallbackColors[Int(seed % UInt64(fallbackColors.count))],
            symbolName: fallbackSymbols[Int((seed / 13) % UInt64(fallbackSymbols.count))]
        )
    }

    /// Vivid, dark-and-light-safe accents for generated logos.
    private static let fallbackColors: [String] = [
        "#FF6B6B", "#FD9644", "#F7B731", "#26DE81", "#2BCBBA",
        "#45B8AC", "#4B7BEC", "#5D9CEC", "#A55EEA", "#EB6B9D",
        "#778CA3", "#20BF6B",
    ]

    /// Everyday-spending symbols for generated logos.
    private static let fallbackSymbols: [String] = [
        "cart.fill", "bag.fill", "basket.fill", "fork.knife",
        "cup.and.saucer.fill", "car.fill", "fuelpump.fill", "house.fill",
        "gift.fill", "gamecontroller.fill", "airplane", "tram.fill",
        "pawprint.fill", "book.fill", "scissors", "wrench.and.screwdriver.fill",
        "tshirt.fill", "pills.fill", "leaf.fill", "music.note",
    ]

    /// djb2 — `String.hashValue` is randomized per launch, so it can't seed
    /// anything that must be stable across sessions.
    private static func stableHash(_ string: String) -> UInt64 {
        var hash: UInt64 = 5381
        for byte in string.utf8 {
            hash = (hash &* 33) &+ UInt64(byte)
        }
        return hash
    }
}

extension Expense {
    /// Resolved logo asset name from the template catalog (nil if no match).
    var logoName: String? { SubscriptionTemplate.logoName(for: name) }

    /// Resolved logo customization — saved override → template defaults →
    /// neutral fallback. Use this everywhere an `Expense` is rendered so
    /// every site matches the popular-expenses picker look.
    func logoCustomization(in store: AppStore) -> LogoCustomization {
        LogoCustomization.resolved(for: id, name: name, in: store)
    }
}
