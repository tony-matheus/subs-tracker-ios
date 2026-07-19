import SwiftUI

/// Informational card shared by the Privacy and "How My Data Is Saved" pages:
/// icon + title header over a block of secondary copy.
struct SettingsInfoCard: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        GlassSection {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .iconStyle(size: 16, weight: .medium, color: .secondary)
                        .frame(width: 24)
                    Text(title)
                        .typography(.bodyLarge)
                        .foregroundStyle(.primary)
                }
                Text(text)
                    .typography(.bodyMedium)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }
}

/// What the app does — and deliberately doesn't do — with the user's data.
/// Descriptive, not legal boilerplate: everything here mirrors the actual
/// architecture (local-only storage, no networking, on-device OCR).
struct PrivacySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    SettingsInfoCard(
                        icon: "iphone",
                        title: "Your data stays on this device",
                        text: "Everything you add — expenses, subscriptions, logos and preferences — is stored only on this device. Nothing is sent to a server, and the app keeps no cloud copy."
                    )

                    SettingsInfoCard(
                        icon: "person.crop.circle.badge.xmark",
                        title: "No account, no sign-in",
                        text: "There's no sign-up, login or profile. The app has no way to identify you and nothing to link your spending to."
                    )

                    SettingsInfoCard(
                        icon: "eye.slash",
                        title: "No tracking, no ads",
                        text: "The app contains no analytics, no ad networks and no third-party trackers. It doesn't phone home."
                    )

                    SettingsInfoCard(
                        icon: "doc.text.viewfinder",
                        title: "Receipt scanning is on-device",
                        text: "Receipts are read with Apple's on-device text recognition. The photo is processed right on your device and is never uploaded anywhere."
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .appBackground()
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

#Preview {
    PrivacySheet()
}
