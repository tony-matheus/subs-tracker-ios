import Foundation

enum StorageService {
    private static let subscriptionsKey = "subscriptions"
    private static let settingsKey = "app_settings"
    private static let customizationsKey = "logo_customizations"

    // MARK: - Subscriptions

    static func save(_ subscriptions: [Subscription]) {
        if let data = try? JSONEncoder().encode(subscriptions) {
            UserDefaults.standard.set(data, forKey: subscriptionsKey)
        }
    }

    static func load() -> [Subscription] {
        guard let data = UserDefaults.standard.data(forKey: subscriptionsKey),
              let decoded = try? JSONDecoder().decode([Subscription].self, from: data)
        else {
            return []
        }
        return decoded
    }

    // MARK: - Settings

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

    // MARK: - Logo Customizations

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
