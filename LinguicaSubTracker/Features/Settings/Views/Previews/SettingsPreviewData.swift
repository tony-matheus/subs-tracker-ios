import Foundation

enum SettingsPreviewData {
    static func makeStore() -> AppStore {
        let s = AppStore()
        s.subscriptions = [
            Subscription(
                name: "Netflix",
                price: 15.99,
                schedule: .monthly,
                startDate: Date(),
                category: "Entertainment",
                list: "Personal"
            ),
        ]
        return s
    }

    static func makeSettingsStore() -> SettingsStore {
        SettingsStore()
    }
}
