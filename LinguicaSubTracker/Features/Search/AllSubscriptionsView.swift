import SwiftUI

enum SubscriptionSortType: String, CaseIterable, Identifiable {
    case status, name, price, renewal, paymentMethod
    var id: String { rawValue }

    var label: String {
        switch self {
        case .status: return "Status"
        case .name: return "Name"
        case .price: return "Price"
        case .renewal: return "Renewal"
        case .paymentMethod: return "Payment Method"
        }
    }

    var defaultDirection: SortDirection {
        switch self {
        case .price, .renewal: return .descending
        case .name, .status, .paymentMethod: return .ascending
        }
    }
}

enum SortDirection {
    case ascending, descending

    var arrow: String {
        self == .ascending ? "arrow.up" : "arrow.down"
    }

    mutating func toggle() {
        self = self == .ascending ? .descending : .ascending
    }
}

struct AllSubscriptionsView: View {
    @EnvironmentObject private var store: AppStore

    let heroNS: Namespace.ID
    var onClose: () -> Void
    var onPushSubscription: (Subscription) -> Void

    @State private var sort: SubscriptionSortType = .price
    @State private var direction: SortDirection = .descending

    private var sorted: [Subscription] {
        let subs = store.subscriptions
        let asc = direction == .ascending
        switch sort {
        case .status:
            return subs.sorted { lhs, rhs in
                if lhs.isActive == rhs.isActive {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return asc ? (!lhs.isActive && rhs.isActive) : (lhs.isActive && !rhs.isActive)
            }
        case .name:
            return subs.sorted {
                let result = $0.name.localizedCaseInsensitiveCompare($1.name)
                return asc ? result == .orderedAscending : result == .orderedDescending
            }
        case .price:
            return subs.sorted { asc ? $0.price < $1.price : $0.price > $1.price }
        case .renewal:
            return subs.sorted { lhs, rhs in
                let l = SubscriptionService.nextPayment(for: lhs) ?? .distantFuture
                let r = SubscriptionService.nextPayment(for: rhs) ?? .distantFuture
                return asc ? l < r : l > r
            }
        case .paymentMethod:
            return subs.sorted {
                let l = $0.paymentMethod ?? ""
                let r = $1.paymentMethod ?? ""
                let result = l.localizedCaseInsensitiveCompare(r)
                return asc ? result == .orderedAscending : result == .orderedDescending
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 8)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(sorted.enumerated()), id: \.element.id) { index, sub in
                        SubscriptionRow(subscription: sub) {
                            onPushSubscription(sub)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))

                        if index < sorted.count - 1 {
                            Divider().padding(.leading, 76)
                        }
                    }
                }
                .padding(.top, 12)
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: sort)
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: direction)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("All Subs")
                .typography(.displaySmall.weight(.bold))
                .foregroundStyle(.primary)

            sortChip
                .matchedGeometryEffect(id: "all-subs-pill", in: heroNS)

            Spacer()

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .iconStyle(size: 14, weight: .bold)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var sortChip: some View {
        Menu {
            ForEach(SubscriptionSortType.allCases) { type in
                Button {
                    handleSortPick(type)
                } label: {
                    HStack {
                        Text(type.label)
                        if type == sort {
                            Spacer()
                            Image(systemName: direction.arrow)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(sort.label)
                    .typography(.bodyMedium.weight(.semibold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func handleSortPick(_ type: SubscriptionSortType) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            if sort == type {
                direction.toggle()
            } else {
                sort = type
                direction = type.defaultDirection
            }
        }
    }
}
