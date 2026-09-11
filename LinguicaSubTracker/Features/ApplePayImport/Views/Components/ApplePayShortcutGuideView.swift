import SwiftUI

struct ApplePayShortcutGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header card
                    GlassSection {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 56, height: 56)
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Automate Apple Pay")
                                    .typography(.titleLarge)
                                    .foregroundStyle(.primary)
                                Text("Import purchases automatically whenever you pay with Apple Pay.")
                                    .typography(.bodyMedium)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Text("How to setup in iOS Shortcuts:")
                        .typography(.titleMedium)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 4)

                    // Step 1
                    stepRow(
                        number: "1",
                        title: "Open Shortcuts App",
                        description: "Open the Shortcuts app on your iPhone and tap the 'Automation' tab at the bottom.",
                        icon: "square.stack.3d.up.fill"
                    )

                    // Step 2
                    stepRow(
                        number: "2",
                        title: "Create Automation",
                        description: "Tap '+' and scroll down to select 'Transaction' or 'Wallet / Apple Pay' as the trigger.",
                        icon: "plus.circle.fill"
                    )

                    // Step 3
                    stepRow(
                        number: "3",
                        title: "Add Action",
                        description: "Search for 'Import Apple Pay' from Satoru / LinguicaSubTracker action list.",
                        icon: "bolt.fill"
                    )

                    // Step 4
                    stepRow(
                        number: "4",
                        title: "Set Run Immediately",
                        description: "Turn off 'Ask Before Running' so payments are categorized and saved silently in the background.",
                        icon: "checkmark.seal.fill"
                    )

                    AppButton(
                        title: "Open Shortcuts App",
                        icon: "arrow.up.forward.app",
                        style: .primary,
                        expands: true
                    ) {
                        if let url = URL(string: "shortcuts://") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .appBackground()
            .navigationTitle("Apple Pay Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .typography(.labelLarge)
                }
            }
        }
    }

    private func stepRow(number: String, title: String, description: String, icon: String) -> some View {
        GlassSection {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.appPurple.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Text(number)
                        .typography(.titleSmall)
                        .foregroundStyle(Color.appPurple)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .typography(.titleSmall)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundStyle(Color.appPurple)
                    }

                    Text(description)
                        .typography(.bodySmall)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

#Preview {
    ApplePayShortcutGuideView()
}
