import Foundation

enum SubscriptionService {

    // MARK: - Core rule engine

    static func isActive(on date: Date, subscription: Subscription) -> Bool {
        let calendar = Calendar.current

        if !subscription.isActive {
            return false
        }

        if let endDate = subscription.endDate,
           date > endDate {
            return false
        }

        if date < subscription.startDate {
            return false
        }

        switch subscription.schedule {

        case .monthly:
            return calendar.component(.day, from: date)
                == calendar.component(.day, from: subscription.startDate)

        case .yearly:
            return calendar.component(.month, from: date)
                == calendar.component(.month, from: subscription.startDate)
            && calendar.component(.day, from: date)
                == calendar.component(.day, from: subscription.startDate)
        }
    }

    // MARK: - Filter for a specific date (calendar rendering)

    static func subscriptions(for date: Date, subs: [Subscription]) -> [Subscription] {
        subs.filter { isActive(on: date, subscription: $0) }
    }

    // MARK: - Monthly total (financial engine)

    static func totalForMonth(_ subs: [Subscription], month: Date) -> Double {
        let calendar = Calendar.current

        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstOfMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: month)
              )
        else { return 0 }

        var total: Double = 0

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                let activeSubs = subscriptions(for: date, subs: subs)

                total += activeSubs.reduce(0) { $0 + $1.price }
            }
        }

        return total
    }
}
