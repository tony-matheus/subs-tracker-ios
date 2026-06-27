import SwiftUI

struct SubscriptionTemplate: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let primaryColorHex: String
    let secondaryColorHex: String?
    let shadowColorHex: String?
    let backgroundColorHex: String?
    let logo: String?

    init(
        name: String,
        primaryColorHex: String,
        secondaryColorHex: String? = nil,
        shadowColorHex: String? = nil,
        backgroundColorHex: String? = nil,
        logo: String? = nil
    ) {
        self.name = name
        self.primaryColorHex = primaryColorHex
        self.secondaryColorHex = secondaryColorHex
        self.shadowColorHex = shadowColorHex
        self.backgroundColorHex = backgroundColorHex
        self.logo = logo
    }

    /// Display color used in template grids (background → primary).
    var displayColor: Color {
        if let backgroundColorHex { return Color(hex: backgroundColorHex) }
        return Color(hex: primaryColorHex)
    }

    /// Build a customization seeded with the template's colors.
    /// `symbolName` is left nil so `LogoCircle` falls back to the bundle logo asset.
    func makeCustomization(id: UUID) -> LogoCustomization {
        LogoCustomization(
            id: id,
            primaryColorHex: primaryColorHex,
            secondaryColorHex: secondaryColorHex,
            shadowColorHex: shadowColorHex,
            backgroundColorHex: backgroundColorHex,
            style: .symbol,
            symbolName: nil
        )
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// Case-insensitive exact match, then localized-contains either direction.
    /// Single source of truth used by `logoName(for:)` and the unified
    /// logo-resolution helper on `LogoCustomization`.
    static func template(matching name: String) -> SubscriptionTemplate? {
        mock.first {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }
            ?? mock.first {
                $0.name.localizedCaseInsensitiveContains(name)
                    || name.localizedCaseInsensitiveContains(
                        $0.name
                    )
            }
    }

    /// Returns the logo asset name for a given subscription name, using case-insensitive matching.
    static func logoName(for name: String) -> String? {
        template(matching: name)?.logo
    }

    // MARK: - Preview

    static var mockPreview: some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 20),
            count: 3
        )
        return ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(mock) { template in
                    VStack(spacing: 8) {
                        LogoCircle(
                            size: 72,
                            customization: template.makeCustomization(id: template.id),
                            logoName: template.logo,
                            name: template.name
                        )
                        Text(template.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .frame(height: 48, alignment: .top)
                    }
                }
            }
            .padding()
        }
        .background(.black)
    }

    static let mock: [SubscriptionTemplate] = [
        .init(name: "1Password", primaryColorHex: "#1A8CFF", logo: "1Password-logo"),
        .init(name: "Apple Music", primaryColorHex: "#FC3C44", backgroundColorHex: "#F6F6F5", logo: "apple-music-logo"),
        .init(name: "Apple Care", primaryColorHex: "#FC3C44", logo: "apple-care-logo"),
        .init(name: "Apple One", primaryColorHex: "#FC3C44", backgroundColorHex: "#F6F6F5", logo: "apple-one-logo"),
        .init(name: "Amazon Prime Video", primaryColorHex: "#00A8E1", logo: "prime-video-logo"),
        .init(name: "ChatGPT", primaryColorHex: "#10A37F", logo: "chatgpt-logo"),
        .init(name: "Claude", primaryColorHex: "#CC785C", logo: "claude-logo"),
        .init(name: "Crunchyroll", primaryColorHex: "#F47521", backgroundColorHex: "#F6F6F5", logo: "crunchyroll-logo"),
        .init(name: "Cursor", primaryColorHex: "#000000", logo: "cursor-logo"),
        .init(name: "Disney+", primaryColorHex: "#113CCF", logo: "disney-plus-logo"),
        .init(name: "F1 TV", primaryColorHex: "#e2100c", backgroundColorHex: "#F6F6F5", logo: "f1-logo"),
        .init(name: "iCloud", primaryColorHex: "#3478F6", backgroundColorHex: "#F6F6F5", logo: "apple-icloud-logo"),
        .init(name: "LinkedIn Premium", primaryColorHex: "#0A66C2", backgroundColorHex: "#F6F6F5", logo: "linkedin-logo"),
        .init(name: "Netflix", primaryColorHex: "#E50914", backgroundColorHex: "#000000", logo: "netflix-logo"),
        .init(name: "Slack", primaryColorHex: "#4A154B", logo: "slack-logo"),
        .init(name: "Spotify", primaryColorHex: "#1DB954", backgroundColorHex: "#000000", logo: "spotify-logo"),
        .init(name: "Twitter/X", primaryColorHex: "#000000", logo: "x-logo"),
        .init(name: "Uber One", primaryColorHex: "#000000", logo: "uber-one-logo"),
        .init(name: "YouTube", primaryColorHex: "#FF0000", backgroundColorHex: "#F6F6F5", logo: "youtube-logo"),
        .init(name: "YouTube Music", primaryColorHex: "#FF0000", backgroundColorHex: "#F6F6F5", logo: "youtube-music-logo"),
        .init(name: "Xbox Game Pass", primaryColorHex: "#107C10", logo: "xbox-game-pass-logo"),
    ]
}

#Preview("All Templates") {
    SubscriptionTemplate.mockPreview
}
