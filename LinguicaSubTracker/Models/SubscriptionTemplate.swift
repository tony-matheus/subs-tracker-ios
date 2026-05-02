import SwiftUI

struct SubscriptionTemplate: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: Color

    static let mock: [SubscriptionTemplate] = [
        .init(name: "YouTube", color: .red),
        .init(name: "Spotify", color: .green),
        .init(name: "Netflix", color: .black),
        .init(name: "LinkedIn", color: .blue),
        .init(name: "Cursor", color: .gray),
        .init(name: "Claude", color: .orange),
        .init(name: "ChatGPT", color: .gray),
        .init(name: "iCloud", color: .blue),
        .init(name: "Apple One", color: .white),
        .init(name: "Apple Music", color: .red),
        .init(name: "Amazong Prime Video", color: .blue),
        .init(name: "1Password", color: .blue),
        .init(name: "Crunchyroll", color: .orange),
        .init(name: "Disney+", color: .blue),
        .init(name: "Amazong Prime Video", color: .blue),
        .init(name: "Slack", color: .red),
        .init(name: "Uber One", color: .gray),
        .init(name: "Twitter/X", color: .black),
        .init(name: "Xbox Game Pass", color: .green),
        .init(name: "YouTube Music", color: .red)
    ]
}
