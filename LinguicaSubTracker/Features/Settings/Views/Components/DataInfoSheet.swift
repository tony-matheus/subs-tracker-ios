import SwiftUI

/// "How my data is saved" — plain-language explanation of the app's
/// local-only persistence and what each destructive Settings action does.
/// Wording for the two danger-zone actions mirrors the SettingsView alerts.
struct DataInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    SettingsInfoCard(
                        icon: "internaldrive",
                        title: "Where it lives",
                        text: "All data is saved in the app's private storage on this device. There's no account and no cloud sync — your device's regular iOS backup is the only copy that ever exists outside the app."
                    )

                    SettingsInfoCard(
                        icon: "tray.full",
                        title: "What's saved",
                        text: "Your expenses and their billing details, any logo customizations, and your preferences: currency, categories, payment methods, lists, budget, appearance and calendar style."
                    )

                    SettingsInfoCard(
                        icon: "trash",
                        title: "Delete All Data",
                        text: "Permanently deletes all expenses and their logos. Categories, payment methods, lists, budget and appearance stay as configured. This can't be undone."
                    )

                    SettingsInfoCard(
                        icon: "arrow.counterclockwise",
                        title: "Reset App Completely",
                        text: "Permanently deletes every expense, category, payment method, list and preference, then restarts onboarding as if freshly installed. This can't be undone."
                    )

                    SettingsInfoCard(
                        icon: "xmark.bin",
                        title: "Deleting the app",
                        text: "Because nothing is stored anywhere else, removing the app from your device removes everything with it."
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .appBackground()
            .navigationTitle("How My Data Is Saved")
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
    DataInfoSheet()
}
