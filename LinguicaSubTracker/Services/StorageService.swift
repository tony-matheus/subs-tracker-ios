import Foundation

enum StorageService {
    private static let key = "subscriptions"

    static func save(_ subscriptions: [Subscription]) {
        if let data = try? JSONEncoder().encode(subscriptions) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load() -> [Subscription] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Subscription].self, from: data)
        else {
            return []
        }
        return decoded
    }
}
