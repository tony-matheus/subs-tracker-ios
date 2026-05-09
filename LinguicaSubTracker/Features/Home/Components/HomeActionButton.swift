import SwiftUI

struct HomeActionButton: View {
    let isOnCurrentMonth: Bool
    var onAdd: () -> Void
    var onBackToCurrent: () -> Void

    private var swapTransition: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.5).combined(with: .offset(y: -40)).combined(with: .opacity),
            removal: .scale(scale: 0.5).combined(with: .offset(y: 40)).combined(with: .opacity)
        )
    }

    var body: some View {
        ZStack {
            if isOnCurrentMonth {
                addButton
                    .transition(swapTransition)
            } else {
                backButton
                    .transition(swapTransition)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.62), value: isOnCurrentMonth)
    }

    private var addButton: some View {
        Button(action: onAdd) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.purple)
                Text("Add subscription")
                    .typography(.bodyMedium.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var backButton: some View {
        Button(action: onBackToCurrent) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.uturn.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary)
                Text("Back to current")
                    .typography(.bodyMedium.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct Demo: View {
        @State var current = true
        var body: some View {
            VStack(spacing: 40) {
                HomeActionButton(
                    isOnCurrentMonth: current,
                    onAdd: { current.toggle() },
                    onBackToCurrent: { current.toggle() }
                )
                Button("Toggle") { current.toggle() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        }
    }
    return Demo()
}
