import SwiftUI

struct SubscriptionTemplate: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let brandHex: String?
    let backgroundHex: String?
    let fallbackColor: Color
    let logo: String?

    /// Resolves display color: backgroundHex → brandHex → fallbackColor
    var color: Color {
        if let hex = backgroundHex { return Color(hex: hex) }
        if let hex = brandHex { return Color(hex: hex) }
        return fallbackColor
    }

    init(
        name: String,
        brandHex: String? = nil,
        backgroundHex: String? = nil,
        fallbackColor: Color,
        logo: String? = nil
    ) {
        self.name = name
        self.brandHex = brandHex
        self.backgroundHex = backgroundHex
        self.fallbackColor = fallbackColor
        self.logo = logo
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// Returns the logo asset name for a given subscription name, using case-insensitive matching.
    static func logoName(for subscriptionName: String) -> String? {
        mock.first {
            $0.name.caseInsensitiveCompare(subscriptionName) == .orderedSame
        }?.logo
            ?? mock.first {
                $0.name.localizedCaseInsensitiveContains(subscriptionName)
                    || subscriptionName.localizedCaseInsensitiveContains(
                        $0.name
                    )
            }?.logo
    }

    static let mock: [SubscriptionTemplate] = [
        .init(
            name: "1Password",
            brandHex: "#1A8CFF",
            fallbackColor: .blue,
            logo: "1Password-logo"
        ),
        .init(
            name: "Apple Music",
            brandHex: "#FC3C44",
            fallbackColor: .red,
            logo: "apple-music-logo"
        ),
        .init(
            name: "Amazon Prime Video",
            brandHex: "#00A8E1",
            fallbackColor: .blue,
            logo: "prime-video-logo"
        ),
        .init(
            name: "ChatGPT",
            brandHex: "#10A37F",
            fallbackColor: .gray,
            logo: "chatgpt-logo"
        ),
        .init(
            name: "Claude",
            brandHex: "#CC785C",
            fallbackColor: .orange,
            logo: "claude-logo"
        ),
        .init(
            name: "Crunchyroll",
            brandHex: "#F47521",
            fallbackColor: .orange,
            logo: "crunchyroll-logo"
        ),
        .init(
            name: "Cursor",
            brandHex: "#000000",
            fallbackColor: .gray,
            logo: "cursor-logo"
        ),
        .init(
            name: "Disney+",
            brandHex: "#113CCF",
            fallbackColor: .blue,
            logo: "disney-plus-logo"
        ),
        .init(
            name: "iCloud",
            brandHex: "#3478F6",
            fallbackColor: .blue,
            logo: nil
        ),
        .init(
            name: "LinkedIn",
            brandHex: "#0A66C2",
            fallbackColor: .blue,
            logo: "linkedin-logo"
        ),
        .init(
            name: "Netflix",
            brandHex: "#E50914",
            backgroundHex: "#000000",
            fallbackColor: .black,
            logo: "netflix-logo"
        ),
        .init(
            name: "Slack",
            brandHex: "#4A154B",
            fallbackColor: .red,
            logo: "slack-logo"
        ),
        .init(
            name: "Spotify",
            brandHex: "#1DB954",
            fallbackColor: .green,
            logo: "spotify-logo"
        ),
        .init(
            name: "Twitter/X",
            brandHex: "#000000",
            fallbackColor: .black,
            logo: "x-logo"
        ),
        .init(
            name: "Uber One",
            brandHex: "#000000",
            fallbackColor: .gray,
            logo: "uber-one-logo"
        ),
        .init(
            name: "YouTube",
            brandHex: "#FF0000",
            fallbackColor: .red,
            logo: "youtube-logo"
        ),
        .init(
            name: "YouTube Music",
            brandHex: "#FF0000",
            fallbackColor: .red,
            logo: "youtube-music-logo"
        ),
        .init(
            name: "Xbox Game Pass",
            brandHex: "#107C10",
            fallbackColor: .green,
            logo: "xbox-game-pass-logo"
        ),
    ]
}
