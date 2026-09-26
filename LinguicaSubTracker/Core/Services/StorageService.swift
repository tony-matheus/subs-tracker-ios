import Foundation
import WidgetKit

enum StorageService {
    private static let expensesKey = "expenses"
    private static let legacyExpensesKey = "subscriptions"
    private static let settingsKey = "app_settings"
    private static let customizationsKey = "logo_customizations"
    private static let onboardingKey = "has_completed_onboarding"

    static let appGroupID = "group.com.dtx.LinguicaSubTracker"
    /// App Group suite for expenses, settings and logos, so the widget
    /// extension reads the same data. App-only state (onboarding, iCloud
    /// toggle, CloudKit engine state) stays in `.standard`.
    static let shared = UserDefaults(suiteName: appGroupID) ?? .standard

    /// Reads `key` from the shared suite, first moving a pre-App-Group value
    /// over from `.standard` (one time per key).
    private static func storedData(forKey key: String) -> Data? {
        migrateIfNeeded(key, from: .standard, to: shared)
        return shared.data(forKey: key)
    }

    static func migrateIfNeeded(_ key: String, from old: UserDefaults, to new: UserDefaults) {
        guard old !== new, new.object(forKey: key) == nil,
              let value = old.object(forKey: key) else { return }
        new.set(value, forKey: key)
        old.removeObject(forKey: key)
    }

    /// Every write lands here, from the UI, Siri intents or iCloud sync.
    private static func write(_ data: Data, forKey key: String) {
        shared.set(data, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: onboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: onboardingKey) }
    }

    static func save(_ expenses: [Expense]) {
        if let data = try? JSONEncoder().encode(expenses) {
            write(data, forKey: expensesKey)
        }
    }

    static func load() -> [Expense] {
        let defaults = UserDefaults.standard

        // Current key.
        if let data = storedData(forKey: expensesKey),
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
            write(data, forKey: settingsKey)
        }
    }

    static func loadSettings() -> AppSettings {
        guard let data = storedData(forKey: settingsKey),
              let decoded = try? JSONDecoder().decode(AppSettings.self, from: data)
        else {
            return .default
        }
        return decoded
    }


    static func saveCustomizations(_ customizations: [UUID: LogoCustomization]) {
        if let data = try? JSONEncoder().encode(customizations) {
            write(data, forKey: customizationsKey)
        }
    }

    static func loadCustomizations() -> [UUID: LogoCustomization] {
        guard let data = storedData(forKey: customizationsKey),
              let decoded = try? JSONDecoder().decode([UUID: LogoCustomization].self, from: data)
        else {
            return [:]
        }
        return decoded
    }
}
