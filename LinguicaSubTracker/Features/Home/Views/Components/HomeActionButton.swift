import SwiftUI

struct HomeActionButton: View {
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
                            Color.green.gradient
                        )
                        Text("Add expense")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primary.gradient)
                }
                .id(isOnCurrentMonth)
                .transition(.liquidRipple)
            } else {
                Button(action: onBackToCurrent) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.uturn.left")
                            .foregroundStyle(
                                Color.purple.gradient
                            )
                        Text("Today")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primary.gradient)
                }
                .id(isOnCurrentMonth)
                .transition(.liquidRipple)
            }
        }
        .animation(
            .spring(response: 0.5, dampingFraction: 0.62),
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
            .background(Color.black)
        }
    }
    return Demo()
}
