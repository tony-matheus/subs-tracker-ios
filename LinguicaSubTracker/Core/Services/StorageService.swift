import Foundation

enum StorageService {
    private static let expensesKey = "expenses"
    private static let legacyExpensesKey = "subscriptions"
    private static let settingsKey = "app_settings"
    private static let customizationsKey = "logo_customizations"
    private static let onboardingKey = "has_completed_onboarding"
    private static let iCloudSyncKey = "icloud_sync_enabled"

    /// Keys mirrored to iCloud when sync is on.
    private static let syncedKeys = [expensesKey, settingsKey, customizationsKey]

    static var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: onboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: onboardingKey) }
    }

    // MARK: - iCloud (key-value store mirror)
    //
    // DISABLED until the paid developer account is set up — the ubiquity
    // entitlement fails signing on a personal team. To re-enable: uncomment
    // the bodies below, restore CODE_SIGN_ENTITLEMENTS in the pbxproj
    // (LinguicaSubTracker/LinguicaSubTracker.entitlements still exists), and
    // uncomment the KVS observer in AppStore.init + the Settings toggle.
    //
    // ponytail: NSUbiquitousKeyValueStore caps at 1MB total — enough for
    // thousands of expenses; move to CloudKit/iCloud Drive if data outgrows it.

    static var iCloudSyncEnabled: Bool {
        false
        // UserDefaults.standard.bool(forKey: iCloudSyncKey)
    }

    /// Pushes the current local data to iCloud (call when sync turns on).
    static func pushAllToICloud() {
        // let cloud = NSUbiquitousKeyValueStore.default
        // for key in syncedKeys {
        //     if let data = UserDefaults.standard.data(forKey: key) {
        //         cloud.set(data, forKey: key)
        //     }
        // }
        // cloud.synchronize()
    }

    /// Copies iCloud data into local storage (external-change import).
    /// Last writer wins — same semantics the key-value store itself has.
    static func importFromICloud() {
        // guard iCloudSyncEnabled else { return }
        // let cloud = NSUbiquitousKeyValueStore.default
        // for key in syncedKeys {
        //     if let data = cloud.data(forKey: key) {
        //         UserDefaults.standard.set(data, forKey: key)
        //     }
        // }
    }

    private static func mirrorToICloud(_ data: Data, forKey key: String) {
        // guard iCloudSyncEnabled else { return }
        // NSUbiquitousKeyValueStore.default.set(data, forKey: key)
    }


    static func save(_ expenses: [Expense]) {
        if let data = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(data, forKey: expensesKey)
            mirrorToICloud(data, forKey: expensesKey)
        }
    }

    static func load() -> [Expense] {
        let defaults = UserDefaults.standard

        // Current key.
        if let data = defaults.data(forKey: expensesKey),
           let decoded = try? JSONDecoder().decode([Expense].self, from: data) {
            return decoded
        }

        // One-time migration: pre-rename data lived under "subscriptions".
        // The backward-compatible decoder reads the legacy `schedule` key.
        if let legacy = defaults.data(forKey: legacyExpensesKey),
           let decoded = try? JSONDecoder().decode([Expense].self, from: legacy) {
            save(decoded)
            defaults.removeObject(forKey: legacyExpensesKey)
            return decoded
        }

        return []
    }


    static func saveSettings(_ settings: AppSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
            mirrorToICloud(data, forKey: settingsKey)
        }
    }

    static func loadSettings() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: settingsKey),
              let decoded = try? JSONDecoder().decode(AppSettings.self, from: data)
        else {
            return .default
        }
        return decoded
    }


    static func saveCustomizations(_ customizations: [UUID: LogoCustomization]) {
        if let data = try? JSONEncoder().encode(customizations) {
            UserDefaults.standard.set(data, forKey: customizationsKey)
            mirrorToICloud(data, forKey: customizationsKey)
        }
    }

    static func loadCustomizations() -> [UUID: LogoCustomization] {
        guard let data = UserDefaults.standard.data(forKey: customizationsKey),
              let decoded = try? JSONDecoder().decode([UUID: LogoCustomization].self, from: data)
        else {
            return [:]
        }
        return decoded
    }
}
