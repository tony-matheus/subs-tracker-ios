import Foundation

extension LogoCustomization {
    /// Single source of truth for resolving a subscription's logo customization.
    ///
    /// Resolution order:
    /// 1. User-saved override in `AppStore.logoCustomizations`.
    /// 2. Template defaults via `SubscriptionTemplate.template(matching:)`
    ///    (matches the look used by `SubscriptionListSheet`).
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
        return LogoCustomization(
            id: id,
            primaryColorHex: "#F6F6F5",
            symbolName: nil
        )
    }
}

extension Subscription {
    /// Resolved logo asset name from the template catalog (nil if no match).
    var logoName: String? { SubscriptionTemplate.logoName(for: name) }

    /// Resolved logo customization — saved override → template defaults →
    /// neutral fallback. Use this everywhere a `Subscription` is rendered so
    /// every site matches the `SubscriptionListSheet` picker look.
    func logoCustomization(in store: AppStore) -> LogoCustomization {
        LogoCustomization.resolved(for: id, name: name, in: store)
    }
}
