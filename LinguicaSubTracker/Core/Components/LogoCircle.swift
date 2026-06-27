import SwiftUI
import UIKit

struct LogoCircle: View {
    let size: CGFloat
    let customization: LogoCustomization
    var logoName: String? = nil
    let name: String
    var imageScale: CGFloat = 0.6

    var body: some View {
        ZStack {
            Circle()
                .fill(customization.resolvedBackground)
                .frame(width: size, height: size)
                .glassEffect(.regular.interactive())
                .shadow(
                    color: customization.resolvedShadow.opacity(0.5),
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
        switch customization.style {
        case .symbol:
            symbolOrAssetContent
        case .emoji:
            if let emoji = customization.emoji, !emoji.isEmpty {
                Text(emoji)
                    .font(.system(size: size * 0.55))
            } else {
                fallbackInitials
            }
        case .photo:
            if let data = customization.imageData, let ui = UIImage(data: data)
            {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(customization.imageScale)
                    .offset(
                        x: customization.imageOffsetX * size * 0.5,
                        y: customization.imageOffsetY * size * 0.5
                    )
                    .frame(width: size, height: size)
            } else {
                fallbackInitials
            }
        }
    }

    @ViewBuilder
    private var symbolOrAssetContent: some View {
        if customization.symbolName == nil,
            let logoName,
            UIImage(named: logoName) != nil
        {
            Image(logoName)
                .resizable()
                .scaledToFit()
                .frame(width: size * imageScale, height: size * imageScale)
                .clipShape(Circle())
        } else {
            symbolImage
        }
    }

    @ViewBuilder
    private var symbolImage: some View {
        let base = Image(systemName: customization.symbolName ?? "creditcard.fill")
            .resizable()
            .scaledToFit()
            .fontWeight(.semibold)
            .frame(width: size * 0.5, height: size * 0.5)

        switch customization.symbolRendering {
        case .solid:
            base
                .symbolRenderingMode(.monochrome)
                .symbolColorRenderingMode(.flat)
                .foregroundStyle(customization.resolvedForeground)
        case .multicolor:
            base
                .symbolRenderingMode(.multicolor)
                .symbolColorRenderingMode(.flat)
        case .gradient:
            base
                .symbolRenderingMode(.monochrome)
                .symbolColorRenderingMode(.gradient)
                .foregroundStyle(customization.primaryColor)
        }
    }

    private var fallbackInitials: some View {
        Text(initials(for: name))
            .font(.system(size: size * 0.33, weight: .bold))
            .foregroundColor(customization.resolvedForeground)
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
    @Previewable @State var activeStyle: LogoStyle = .symbol
    @Previewable @State var customizationsByStyle: [LogoStyle: LogoCustomization] = [
        .symbol: LogoCustomization(
            id: UUID(),
            primaryColorHex: "#FC3C44",
            backgroundColorHex: "#F6F6F5",
            style: .symbol,
            symbolName: "xmark.circle.fill"
        ),
        .emoji: LogoCustomization(
            id: UUID(),
            primaryColorHex: "#34C759",
            backgroundColorHex: "#F0FFF4",
            style: .emoji,
            emoji: "🎵"
        ),
        .photo: LogoCustomization(
            id: UUID(),
            primaryColorHex: "#007AFF",
            backgroundColorHex: "#E3F2FD",
            style: .photo
        ),
    ]

    let styles: [LogoStyle] = [.symbol, .emoji, .photo]

    VStack(spacing: 24) {
        Picker("Style", selection: $activeStyle) {
            Text("Symbol").tag(LogoStyle.symbol)
            Text("Emoji").tag(LogoStyle.emoji)
            Text("Photo").tag(LogoStyle.photo)
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 260)

        HStack(spacing: 20) {
            ForEach(styles, id: \.self) { style in
                if let customization = customizationsByStyle[style] {
                    VStack(spacing: 8) {
                        LogoCircle(
                            size: 100,
                            customization: customization,
                            name: "Apple Music"
                        )
                        .opacity(activeStyle == style ? 1.0 : 0.35)
                        .scaleEffect(activeStyle == style ? 1.0 : 0.9)
                        .animation(.spring(duration: 0.3), value: activeStyle)

                        Text(style.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(activeStyle == style ? .primary : .secondary)
                    }
                    .onTapGesture { activeStyle = style }
                }
            }
        }
    }
    .padding()
}
