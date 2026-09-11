import Foundation

/// Centralized Feature Flags for toggling experimental or unreleased features.
enum FeatureFlags {
    /// Controls whether the Apple Pay Import feature (Bento card, Settings row, Hub) is visible to users.
    /// - Set to `true` to enable Apple Pay Import.
    /// - Set to `false` to hide Apple Pay Import completely for public releases.
    static let isApplePayImportEnabled: Bool = true
}
