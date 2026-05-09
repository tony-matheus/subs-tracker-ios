import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var settingsStore: SettingsStore

    let heroNS: Namespace.ID
    var onShowAll: () -> Void
    var onClose: () -> Void
    var onPushSubscription: (Subscription) -> Void

    @State private var searchText: String = ""

    private var hasQuery: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var filtered: [Subscription] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        return store.subscriptions.filter { sub in
            if sub.name.localizedCaseInsensitiveContains(q) { return true }
            let schedule = sub.schedule == .monthly ? "monthly" : "yearly"
            if schedule.contains(q) { return true }
            let status = sub.isActive ? "active" : "inactive"
            if status.contains(q) { return true }
            if let pm = sub.paymentMethod, pm.localizedCaseInsensitiveContains(q) { return true }
            if sub.category.localizedCaseInsensitiveContains(q) { return true }
            return false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.top, 8)

            Group {
                if hasQuery {
                    resultsList
                } else {
                    emptyState
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: hasQuery)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            SearchBar(text: $searchText)

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .iconStyle(size: 14, weight: .bold)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 16)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 22) {
            Spacer()

            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("You can search subscriptions by name, by type such as Monthly, Yearly, Trial, or One-time, or by their status Active, Canceled, or Archived.")
                .typography(.bodyMedium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: onShowAll) {
                Text("All your subscriptions")
                    .typography(.titleMedium.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.1), in: Capsule())
                    .matchedGeometryEffect(id: "all-subs-pill", in: heroNS)
            }
            .buttonStyle(.plain)

            Spacer()
            Spacer()
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if filtered.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary.opacity(0.5))
                        Text("No matches for \"\(searchText)\"")
                            .typography(.bodyMedium)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                    .transition(.opacity)
                } else {
                    ForEach(filtered) { sub in
                        SubscriptionRow(subscription: sub) {
                            onPushSubscription(sub)
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity
                        ))

                        if sub.id != filtered.last?.id {
                            Divider().padding(.leading, 76)
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
        .transition(.opacity)
    }
}
