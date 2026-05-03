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

    // MARK: - Next payment date

    static func nextPayment(for subscription: Subscription, from today: Date = Date()) -> Date? {
        guard subscription.isActive else { return nil }
        let calendar = Calendar.current

        var candidate: Date
        switch subscription.schedule {
        case .monthly:
            let startDay = calendar.component(.day, from: subscription.startDate)
            var components = calendar.dateComponents([.year, .month], from: today)
            components.day = startDay
            guard var base = calendar.date(from: components) else { return nil }
            if base <= today {
                base = calendar.date(byAdding: .month, value: 1, to: base) ?? base
            }
            candidate = base

        case .yearly:
            let startMonth = calendar.component(.month, from: subscription.startDate)
            let startDay   = calendar.component(.day,   from: subscription.startDate)
            var components = DateComponents(
                year: calendar.component(.year, from: today),
                month: startMonth, day: startDay
            )
            guard var base = calendar.date(from: components) else { return nil }
            if base <= today {
                components.year = calendar.component(.year, from: today) + 1
                base = calendar.date(from: components) ?? base
            }
            candidate = base
        }

        if let end = subscription.endDate, candidate > end { return nil }
        return candidate
    }

    // MARK: - Total spent

    static func totalSpent(for subscription: Subscription, until today: Date = Date()) -> Double {
        guard today >= subscription.startDate else { return 0 }
        let calendar = Calendar.current
        var count = 0

        switch subscription.schedule {
        case .monthly:
            let months = calendar.dateComponents([.month], from: subscription.startDate, to: today).month ?? 0
            count = months + 1

        case .yearly:
            let years = calendar.dateComponents([.year], from: subscription.startDate, to: today).year ?? 0
            count = years + 1
        }

        if let end = subscription.endDate {
            switch subscription.schedule {
            case .monthly:
                let capped = calendar.dateComponents([.month], from: subscription.startDate, to: min(today, end)).month ?? 0
                count = capped + 1
            case .yearly:
                let capped = calendar.dateComponents([.year], from: subscription.startDate, to: min(today, end)).year ?? 0
                count = capped + 1
            }
        }

        return Double(max(count, 0)) * subscription.price
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
