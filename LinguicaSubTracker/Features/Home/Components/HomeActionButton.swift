import SwiftUI

struct HomeActionButton: View {
    let isOnCurrentMonth: Bool
    var onAdd: () -> Void
    var onBackToCurrent: () -> Void

    @State private var rippleScale: CGFloat = 0
    @State private var rippleOpacity: Double = 0

    private var iconName: String {
        isOnCurrentMonth ? "plus" : "arrow.uturn.left"
    }

    private var iconColor: Color {
        isOnCurrentMonth ? .purple : .secondary
    }

    private var label: String {
        isOnCurrentMonth ? "Add subscription" : "Back to current"
    }

    private var rippleColor: Color {
        isOnCurrentMonth ? .purple : .white
    }

    var body: some View {
        Button {
            if isOnCurrentMonth {
                onAdd()
            } else {
                onBackToCurrent()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(rippleColor.opacity(rippleOpacity))
                    .frame(width: 30, height: 30)
                    .scaleEffect(rippleScale)
                    .allowsHitTesting(false)

                HStack(spacing: 8) {
                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(iconColor)
                        .contentTransition(.opacity)
                        .id(iconName)
                        .transition(.scale.combined(with: .opacity))

                    Text(label)
                        .typography(.bodyMedium.weight(.semibold))
                        .foregroundStyle(.primary)
                        .id(label)
                        .transition(.opacity)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isOnCurrentMonth)
        .onChange(of: isOnCurrentMonth) { _, _ in
            triggerRipple()
        }
    }

    private func triggerRipple() {
        rippleScale = 0
        rippleOpacity = 0.55
        withAnimation(.easeOut(duration: 0.65)) {
            rippleScale = 7
            rippleOpacity = 0
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HomeActionButton(isOnCurrentMonth: true, onAdd: {}, onBackToCurrent: {})
        HomeActionButton(isOnCurrentMonth: false, onAdd: {}, onBackToCurrent: {})
    }
    .padding()
    .background(Color.black)
}
