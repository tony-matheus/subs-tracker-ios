import SwiftUI

/// Entry point into the popular-services catalog. Shows the applied template
/// once one is picked, so the row doubles as the "filled from" indicator.
/// Stays tappable when filled — the ✕ clears, the rest of the row re-opens
/// the catalog to swap services.
struct PopularServicesRow: View {
    var selectedName: String? = nil
    var accent: Color = .primary
    var onTap: () -> Void
    var onClear: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onTap) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .iconStyle(size: 16, weight: .medium, color: accent)
                        .frame(width: 20)

                    Text(selectedName ?? "Choose a service")
                        .typography(.bodyLarge)
                        .foregroundStyle(selectedName == nil ? accent : .primary)

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if selectedName != nil, let onClear {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .iconStyle(size: 17, weight: .medium, color: accent.opacity(0.7))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear selected service")
            }

            Image(systemName: "chevron.right")
                .iconStyle(size: 13, weight: .semibold, color: accent.opacity(0.6))
        }
        .frame(height: 44)
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.orange, .black], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

        VStack(spacing: 24) {
            LabeledSection("Fill from popular services", titleColor: .white.opacity(0.85)) {
                PopularServicesRow(accent: .white) {}
            }

            LabeledSection("Fill from popular services", titleColor: .white.opacity(0.85)) {
                PopularServicesRow(
                    selectedName: "Spotify",
                    accent: .white,
                    onTap: {},
                    onClear: {}
                )
            }
        }
        .padding()
    }
}
