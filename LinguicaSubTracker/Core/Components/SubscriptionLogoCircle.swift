import SwiftUI

struct SubscriptionLogoCircle: View {
    let size: CGFloat
    let color: Color
    let logoName: String?
    let name: String

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .glassEffect(.regular.interactive())
                .shadow(
                    color: color.opacity(0.5),
                    radius: size * 0.22,
                    x: 0,
                    y: size * 0.08
                )

            if let logoName {
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
    }

    private func initials(for name: String) -> String {
        let words = name.split(separator: " ")
        guard words.count > 1 else {
            return String(name.prefix(2)).uppercased()
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
