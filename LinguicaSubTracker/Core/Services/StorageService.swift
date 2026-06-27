import Foundation

enum StorageService {
    private static let expensesKey = "expenses"
    private static let legacyExpensesKey = "subscriptions"
    private static let settingsKey = "app_settings"
    private static let customizationsKey = "logo_customizations"
    private static let onboardingKey = "has_completed_onboarding"

    static var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: onboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: onboardingKey) }
    }


    static func save(_ expenses: [Expense]) {
        if let data = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(data, forKey: expensesKey)
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
