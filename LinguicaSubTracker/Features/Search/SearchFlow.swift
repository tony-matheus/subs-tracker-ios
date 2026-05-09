import SwiftUI

struct SearchFlow: View {
    @Environment(\.dismiss) private var dismiss
    @State private var stage: Stage = .search
    @State private var path: [Subscription] = []
    @Namespace private var heroNS

    enum Stage { case search, all }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.black.ignoresSafeArea()

                switch stage {
                case .search:
                    SearchView(
                        heroNS: heroNS,
                        onShowAll: showAll,
                        onClose: { dismiss() },
                        onPushSubscription: { sub in path.append(sub) }
                    )
                    .transition(.opacity)
                case .all:
                    AllSubscriptionsView(
                        heroNS: heroNS,
                        onClose: { dismiss() },
                        onPushSubscription: { sub in path.append(sub) }
                    )
                    .transition(.opacity)
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: stage)
            .navigationDestination(for: Subscription.self) { sub in
                SubscriptionSummarySheet(subscription: sub)
            }
        }
    }

    private func showAll() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
            stage = .all
        }
    }
}
