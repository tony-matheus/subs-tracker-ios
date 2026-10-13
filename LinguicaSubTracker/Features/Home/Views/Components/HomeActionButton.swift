import SwiftUI

struct HomeActionButton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isOnCurrentMonth: Bool
    var onAdd: () -> Void
    var onBackToCurrent: () -> Void

    var body: some View {
        ZStack {
            if isOnCurrentMonth {
                Button(action: onAdd) {
                    HStack(spacing: 8) {
                        Image(
                            systemName: "plus"
                        )
                        .foregroundStyle(
                            Color.ink
                        )
                        Text("Add expense")
                    }
                    .typography(.titleMedium)
                    .foregroundStyle(Color.ink)
                }
                .id(isOnCurrentMonth)
                .transition(.opacity)
            } else {
                Button(action: onBackToCurrent) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.uturn.left")
                            .foregroundStyle(
                                Color.ink
                            )
                        Text("Today")
                    }
                    .typography(.titleMedium)
                    .foregroundStyle(Color.ink)
                }
                .id(isOnCurrentMonth)
                .transition(.opacity)
            }
        }
        .animation(
            reduceMotion ? nil : .smooth(duration: 0.25),
            value: isOnCurrentMonth
        )
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
            .background(Color.paper)
        }
    }
    return Demo()
}
