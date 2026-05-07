import Foundation

enum StorageService {
    private static let subscriptionsKey = "subscriptions"
    private static let settingsKey = "app_settings"

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
}
