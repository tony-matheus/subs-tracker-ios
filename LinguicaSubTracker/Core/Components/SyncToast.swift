import SwiftUI

/// Sonner-style pill that drops in from the top when iCloud brings in new
/// data. Auto-dismisses after 2.5s; tap or swipe up to dismiss sooner.
struct SyncToast: View {
    @Binding var message: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dismissTask: Task<Void, Never>?

    var body: some View {
        VStack {
            if let message {
                HStack(spacing: 8) {
                    Image(systemName: "icloud")
                        .iconStyle(size: 14, weight: .semibold, color: .secondary)
                    Text(message)
                        .typography(.bodySmall)
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                // Opaque surface, not a material: the ripple layerEffect
                // renders materials black.
                .background(Color.appSurface, in: Capsule())
                .overlay(Capsule().stroke(Color.primary.opacity(0.08)))
                .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
                .onTapGesture { dismiss() }
                .gesture(DragGesture(minimumDistance: 8).onEnded { value in
                    if value.translation.height < 0 { dismiss() }
                })
                .transition(reduceMotion
                            ? .opacity
                            : .move(edge: .top).combined(with: .opacity))
                .accessibilityAddTraits(.isStaticText)
            }
            Spacer()
        }
        .padding(.top, 8)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: message)
        .onChange(of: message) { _, new in
            guard let new else { return }
            AccessibilityNotification.Announcement(new).post()
            dismissTask?.cancel()
            dismissTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(2.5))
                guard !Task.isCancelled else { return }
                message = nil
            }
        }
    }

    private func dismiss() {
        dismissTask?.cancel()
        message = nil
    }
}

#Preview {
    @Previewable @State var message: String? = nil
    ZStack {
        Color.appSurface.opacity(0.4).ignoresSafeArea()
        Button("Show toast") { message = "3 new transactions synced" }
        SyncToast(message: $message)
    }
}
