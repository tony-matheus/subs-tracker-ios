import SwiftUI

struct SubscriptionSummarySheet: View {
    @EnvironmentObject var store: AppStore

    let subscription: Subscription

    @State private var showDeleteAlert = false
    @State private var showEdit = false
    @State private var isActive: Bool

    init(subscription: Subscription) {
        self.subscription = subscription
        _isActive = State(initialValue: subscription.isActive)
    }

    private var themeColor: Color { Color(hex: subscription.colorHex) }

    private var nextPaymentText: String {
        guard let next = SubscriptionService.nextPayment(for: subscription) else {
            return "—"
        }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: next).day ?? 0
        let formatted = next.formatted(.dateTime.day().month(.wide))
        return "\(formatted) (in \(days) days)"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [themeColor.opacity(0.55), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .blur(radius: 30)
                .frame(height: 320)
                .ignoresSafeArea()
                Spacer()
            }

            ScrollView {
                VStack(spacing: 16) {
                    toolbarRow
                    heroSection
                    detailsBlock
                    categoryBlock
                    listBlock
                    Spacer(minLength: 88)
                }
                .padding()
            }

            deleteButton
        }
        .presentationBackground(.ultraThinMaterial)
        .alert("Delete Subscription", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                store.delete(subscription)
                store.selectedSubscription = nil
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(subscription.name) will be permanently removed.")
        }
        .sheet(isPresented: $showEdit) {
            SubscriptionFormView(
                mode: .edit(subscription),
                onCommit: { updated in
                    store.update(updated)
                    store.selectedSubscription = nil
                }
            )
            .environmentObject(store)
        }
    }

    // MARK: - Toolbar

    private var toolbarRow: some View {
        HStack {
            // Edit (left)
            Button {
                showEdit = true
            } label: {
                Text("Edit")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(themeColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }

            Spacer()

            // Active status picker (right)
            Menu {
                Button("Active")   { toggleActive(true)  }
                Button("Inactive") { toggleActive(false) }
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isActive ? .green : .gray)
                        .frame(width: 8, height: 8)
                    Text(isActive ? "Active" : "Inactive")
                        .font(.subheadline.weight(.medium))
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                Text("Delete Subscription")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .padding()
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 10) {
            SubscriptionLogoCircle(
                size: 72,
                color: themeColor,
                logoName: SubscriptionTemplate.logoName(for: subscription.name),
                name: subscription.name
            )
            .padding(.top, 8)

            Text(subscription.name)
                .font(.title.weight(.bold))

            Text("\(subscription.schedule.rawValue.capitalized) • \(subscription.price.formatted(.currency(code: "CAD")))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }

    // MARK: - Details Block

    private var detailsBlock: some View {
        GlassSection {
            Row(label: "Amount") {
                Text(subscription.price, format: .currency(code: "CAD"))
                    .font(.subheadline)
            }

            Divider()

            Row(label: "Next payment") {
                Text(nextPaymentText)
                    .font(.caption)
                    .multilineTextAlignment(.trailing)
            }

            Divider()

            Row(label: "Total spent") {
                Text(
                    SubscriptionService.totalSpent(for: subscription),
                    format: .currency(code: "CAD")
                )
                .font(.subheadline)
            }
        }
    }

    // MARK: - Category Block

    private var categoryBlock: some View {
        GlassSection {
            Row(label: "Category") {
                HStack(spacing: 6) {
                    Circle()
                        .fill(themeColor)
                        .frame(width: 10, height: 10)
                    Text(subscription.category)
                        .font(.subheadline)
                }
            }
        }
    }

    // MARK: - List Block

    private var listBlock: some View {
        GlassSection {
            Row(label: "List") {
                Text(subscription.list)
                    .font(.subheadline)
            }
        }
    }

    // MARK: - Helpers

    private func toggleActive(_ value: Bool) {
        isActive = value
        var updated = subscription
        updated.isActive = value
        store.update(updated)
    }
}

#Preview {
    let store = AppStore()
    let sub = Subscription(
        name: "Spotify", price: 86.00, colorHex: "#1DB954",
        schedule: .monthly,
        startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!
    )
    store.subscriptions = [sub]
    return Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            SubscriptionSummarySheet(subscription: sub).environmentObject(store)
        }
}
