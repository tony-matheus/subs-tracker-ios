import SwiftUI

struct SubscriptionInDay: View {
    @EnvironmentObject var store: AppStore

    let date: Date

    @State private var showAddSheet = false

    private var subscriptions: [Subscription] {
        SubscriptionService.subscriptions(for: date, subs: store.subscriptions)
    }

    private var total: Double {
        subscriptions.reduce(0) { $0 + $1.price }
    }

    var body: some View {
        VStack(spacing: 0) {
            handle
            header

            ScrollView {
                VStack(spacing: 12) {
                    mainList
                    totalBlock
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 24))
        .presentationDetents([.height(compactHeight)])
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showAddSheet) {
            SubscriptionListSheet(date: date)
        }
    }

    // MARK: - Dynamic height

    // handle(25) + header(~58) + rows + total + padding
    private var compactHeight: CGFloat {
        let rowH: CGFloat = 56
        let rows = CGFloat(subscriptions.count + 1) // +1 for add row
        let total: CGFloat = 72   // total block
        let chrome: CGFloat = 25 + 58 + 12 + 12 + 24
        return min(chrome + rows * rowH + total, 520)
    }

    // MARK: - Handle

    private var handle: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.35))
            .frame(width: 36, height: 5)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 2) {
            Text("Subscriptions")
                .font(.headline)

            Text(date, format: .dateTime.day().month(.wide).year())
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 16)
    }

    // MARK: - Main List

    private var mainList: some View {
        GlassSection {
            ForEach(Array(subscriptions.enumerated()), id: \.element.id) { index, sub in
                if index > 0 { Divider() }
                subscriptionTile(sub)
            }

            if !subscriptions.isEmpty { Divider() }

            addRow
        }
    }

    // MARK: - Subscription Tile

    private func subscriptionTile(_ sub: Subscription) -> some View {
        Button {
            store.selectedSubscription = sub
            store.selectedDay = nil
        } label: {
                HStack(spacing: 12) {
                        SubscriptionLogoCircle(
                            size: 40,
                            color: Color(hex: sub.colorHex),
                            logoName: SubscriptionTemplate.logoName(for: sub.name),
                            name: sub.name
                        )

                VStack(alignment: .leading, spacing: 2) {
                    Text(sub.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(rowSubtitle(for: sub))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func rowSubtitle(for sub: Subscription) -> String {
        let schedule = sub.schedule.rawValue.capitalized
        let price = sub.price.formatted(.currency(code: "CAD"))
        return "\(schedule) • \(price)"
    }

    // MARK: - Add Row

    private var addRow: some View {
        Button {
            showAddSheet = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(UIColor.tertiarySystemFill))
                        .frame(width: 40, height: 40)

                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                }

                Text("Add Subscription")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()
            }
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Total Block

    private var totalBlock: some View {
        GlassSection {
            HStack {
                Text("Total")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(total, format: .currency(code: "CAD"))
                    .font(.subheadline.weight(.bold))
            }
            .frame(height: 44)
        }
    }

}

#Preview {
    let store = AppStore()
    store.subscriptions = [
        Subscription(name: "LinkedIn", price: 52.00, colorHex: "#0077B5", schedule: .monthly, startDate: Date()),
        Subscription(name: "Spotify",  price: 86.00, colorHex: "#1DB954", schedule: .monthly, startDate: Date()),
        Subscription(name: "Youtube",  price: 85.00, colorHex: "#FF0000", schedule: .monthly, startDate: Date()),
    ]
    return Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            SubscriptionInDay(date: Date()).environmentObject(store)
        }
}
