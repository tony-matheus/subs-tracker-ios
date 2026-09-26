import Foundation

/// Feature switches. Each flag is an Active Compilation Condition set once
/// at the project level (Build Settings → Active Compilation Conditions),
/// so every target inherits it.
///
/// To disable a feature, remove its `FF_*` entry there. Its code then
/// doesn't compile at all, which also keeps its intents and controls out of
/// the App Intents metadata (a runtime Bool couldn't hide those).
/// Views check the `static let`s; intents and widgets use `#if FF_*` directly.
enum FeatureFlags {
    /// Local notifications before subscriptions renew.
    #if FF_RENEWALS
    static let renewals = true
    #else
    static let renewals = false
    #endif

    /// Control Center / Action Button control that opens voice capture.
    #if FF_QUICK_ADD
    static let quickAdd = true
    #else
    static let quickAdd = false
    #endif

    /// Receipt scanning with iOS 26 document OCR + on-device model parsing.
    #if FF_SMART_RECEIPTS
    static let smartReceipts = true
    #else
    static let smartReceipts = false
    #endif

    /// Satoru as a Visual Intelligence result for receipts (device-only SDK).
    #if FF_VISUAL_INTELLIGENCE
    static let visualIntelligence = true
    #else
    static let visualIntelligence = false
    #endif
}
