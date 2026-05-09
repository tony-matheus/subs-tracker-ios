import Foundation
import SwiftUI

enum DayStatus {
    case current
    case normal
    case none
}

struct DayCell: View {
    @EnvironmentObject var store: AppStore
    let date: Date?
    var status: DayStatus = .normal
    var height: CGFloat = 68
    var subscriptionCount: Int = 0
    var subscriptions: [Subscription] = []
    var onTap: (Date) -> Void

    private var primarySub: Subscription? { subscriptions.first }
    private var secondarySub: Subscription? { subscriptions.last }
    private var primaryColor: Color? { primarySub.map { Color(hex: $0.colorHex) } }  // used by cellBackground gradient
    private let logoSize: CGFloat = 26
    private let cornerRadius: CGFloat = 20
    private let subscriptionInset: CGFloat = 4
    private let dayLabelInset: CGFloat = 8

    var body: some View {
        Button(action: handleTap) {
            ZStack {
                cellBackground
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay(alignment: .topLeading) {
                if displayDay, let date {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(size: 12))
                        .foregroundStyle(.primary)
                        .opacity(0.6)
                        .padding(.top, dayLabelInset)
                        .padding(.leading, dayLabelInset)
                        .allowsHitTesting(false)
                }
            }
            .overlay {
                if let primary = primarySub {
                    subscriptionFloatingLayer(sub: primary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(borderOverlay)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .buttonStyle(DayClickStyle())
        .disabled(status == .none || date == nil)
    }

    private func handleTap() {
        guard let date else { return }
        onTap(date)
    }

    private func subscriptionFloatingLayer(sub: Subscription) -> some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottomLeading) {
                if let secondSub = secondarySub, subscriptions.count == 2 {
                    logoCircle(sub: secondSub)
                } else if subscriptions.count > 2 {
                    overflowCircle(sub: sub)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                logoCircle(sub: sub)
            }
            .padding(subscriptionInset)
            .allowsHitTesting(false)
    }

    private func logoCircle(sub: Subscription) -> some View {
        SubscriptionLogoCircle(
            size: logoSize,
            color: Color(hex: sub.colorHex),
            logoName: SubscriptionTemplate.logoName(for: sub.name),
            name: sub.name,
            customization: store.customization(for: sub.id)
        )
    }

    private func overflowCircle(sub: Subscription) -> some View {
        let color = Color(hex: sub.colorHex)
        return ZStack {
            Circle()
                .fill(color.opacity(0.55))
                .frame(width: logoSize, height: logoSize)

            Text("+\(subscriptions.count - 1)")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
        }
    }

    @ViewBuilder
    private var cellBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(baseBackgroundColor)
            .overlay(
                Group {
                    if let color = primaryColor, status != .none {
                        LinearGradient(
                            colors: [.clear, color.opacity(0.28)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    }
                }
            )
    }

    private var baseBackgroundColor: Color {
        switch status {
        case .current, .normal: Color.gray.opacity(0.2)
        case .none:             Color.gray.opacity(0.1)
        }
    }

    // MARK: - Border

    @ViewBuilder
    private var borderOverlay: some View {
        switch status {
        case .current:
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.3), lineWidth: 4)
                    .blur(radius: 6)

                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.7),
                                Color.white.opacity(0.1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )

                RoundedRectangle(cornerRadius: cornerRadius)
                    .inset(by: 1)
                    .stroke(Color.white.opacity(0.6), lineWidth: 2)
            }
            .allowsHitTesting(false)
        default:
            EmptyView()
        }
    }

    private var displayDay: Bool { status != .none }
}

struct DayClickStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(
                .spring(duration: 0.2, bounce: 0.4),
                value: configuration.isPressed
            )
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }
}

#Preview {
    let spacing: CGFloat = 4
    let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: 7)
    let weekdaysList = ["S", "M", "T", "W", "T", "F", "S"]
    let cellHeight: CGFloat = 68

    let calendar = Calendar.current
    let weekStart = calendar.date(from: DateComponents(year: 2026, month: 5, day: 3))!
    let weekDates = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }

    let sub1 = Subscription(
        name: "1Password", price: 9.99, colorHex: "#1A8CFF",
        schedule: .monthly, startDate: weekStart
    )
    let sub2 = Subscription(
        name: "Spotify", price: 9.99, colorHex: "#1DB954",
        schedule: .monthly, startDate: weekStart
    )

    // Mirrors MonthView / CalendarView: one sub, one sub, empty, two subs ×2, empty ×2
    let cells: [(DayStatus, [Subscription])] = [
        (.normal, [sub1]),
        (.normal, [sub1]),
        (.current, []),
        (.normal, [sub1, sub2]),
        (.normal, [sub1, sub2]),
        (.normal, []),
        (.normal, []),
    ]

    VStack(spacing: 8) {
        HStack {
            ForEach(Array(weekdaysList.enumerated()), id: \.offset) { _, day in
                Text(day)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.gray)
            }
        }
        .frame(height: 52)

        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(0..<7, id: \.self) { index in
                let (status, subs) = cells[index]
                DayCell(
                    date: weekDates[index],
                    status: status,
                    height: cellHeight,
                    subscriptions: subs,
                    onTap: { _ in }
                )
            }
        }
        .frame(height: cellHeight)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
}

