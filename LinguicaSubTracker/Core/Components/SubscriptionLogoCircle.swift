import SwiftUI
import UIKit

struct SubscriptionLogoCircle: View {
    let size: CGFloat
    let color: Color
    let logoName: String?
    let name: String
    var customization: LogoCustomization? = nil

    private var resolvedColor: Color {
        if let c = customization { return Color(hex: c.colorHex) }
        return color
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(resolvedColor)
                .frame(width: size, height: size)
                .glassEffect(.regular.interactive())
                .shadow(
                    color: resolvedColor.opacity(0.5),
                    radius: size * 0.22,
                    x: 0,
                    y: size * 0.08
                )

            content
                .frame(width: size, height: size)
                .clipShape(Circle())
        }
    }

    @ViewBuilder
    private var content: some View {
        if let custom = customization {
            customContent(custom)
        } else if let logoName {
            Image(logoName)
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.65, height: size * 0.65)
        } else {
            Text(initials(for: name))
                .font(.system(size: size * 0.33, weight: .bold))
                .foregroundColor(.white)
        }
    }

    @ViewBuilder
    private func customContent(_ c: LogoCustomization) -> some View {
        switch c.style {
        case .symbol:
            if let symbol = c.symbolName {
                Image(systemName: symbol)
                    .resizable()
                    .scaledToFit()
                    .fontWeight(.semibold)
                    .frame(width: size * 0.5, height: size * 0.5)
                    .foregroundStyle(.white)
            } else {
                fallbackInitials
            }
        case .emoji:
            if let emoji = c.emoji, !emoji.isEmpty {
                Text(emoji)
                    .font(.system(size: size * 0.55))
            } else {
                fallbackInitials
            }
        case .photo:
            if let data = c.imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(c.imageScale)
                    .offset(x: c.imageOffsetX * size * 0.5, y: c.imageOffsetY * size * 0.5)
                    .frame(width: size, height: size)
            } else {
                fallbackInitials
            }
        }
    }

    private var fallbackInitials: some View {
        Text(initials(for: name))
            .font(.system(size: size * 0.33, weight: .bold))
            .foregroundColor(.white)
    }

    private func initials(for name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "?" }
        let words = trimmed.split(separator: " ")
        guard words.count > 1 else {
            return String(trimmed.prefix(2)).uppercased()
        }
        return (words[0].prefix(1) + words[1].prefix(1)).uppercased()
    }
}

#Preview {
    SubscriptionLogoCircle(
        size: 40,
        color: .black,
        logoName: "netflix-logo",
        name: "1Password"
    )
}
