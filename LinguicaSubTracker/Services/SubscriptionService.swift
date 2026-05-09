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

    // MARK: - Yearly forecasting

    /// Number of remaining payments of `sub` between `start` and end-of-`year` (inclusive).
    static func remainingPaymentCount(
        for sub: Subscription,
        in year: Int,
        from start: Date = Date()
    ) -> Int {
        guard sub.isActive else { return 0 }
        let calendar = Calendar.current
        guard let endOfYear = calendar.date(from: DateComponents(year: year, month: 12, day: 31, hour: 23, minute: 59, second: 59)),
              let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1))
        else { return 0 }

        let windowStart = max(start, startOfYear, sub.startDate)
        let windowEnd = sub.endDate.map { min(endOfYear, $0) } ?? endOfYear
        if windowStart > windowEnd { return 0 }

        switch sub.schedule {
        case .monthly:
            let payDay = calendar.component(.day, from: sub.startDate)
            var count = 0
            // Iterate months from windowStart's month to windowEnd's month
            var cursor = calendar.date(from: calendar.dateComponents([.year, .month], from: windowStart))!
            while cursor <= windowEnd {
                var comps = calendar.dateComponents([.year, .month], from: cursor)
                comps.day = payDay
                if let payDate = calendar.date(from: comps),
                   payDate >= windowStart, payDate <= windowEnd {
                    count += 1
                }
                cursor = calendar.date(byAdding: .month, value: 1, to: cursor) ?? windowEnd
                if calendar.date(byAdding: .month, value: 1, to: cursor) == nil { break }
            }
            return count

        case .yearly:
            let month = calendar.component(.month, from: sub.startDate)
            let day = calendar.component(.day, from: sub.startDate)
            guard let payDate = calendar.date(from: DateComponents(year: year, month: month, day: day)) else { return 0 }
            return (payDate >= windowStart && payDate <= windowEnd) ? 1 : 0
        }
    }

    /// Total $ for `sub` from `start` through end-of-`year`.
    static func projectedAmount(
        for sub: Subscription,
        in year: Int,
        from start: Date = Date()
    ) -> Double {
        Double(remainingPaymentCount(for: sub, in: year, from: start)) * sub.price
    }

    /// Aggregate projected amount across `subs`.
    static func remainingForecast(
        _ subs: [Subscription],
        year: Int,
        from start: Date = Date()
    ) -> Double {
        subs.reduce(0) { $0 + projectedAmount(for: $1, in: year, from: start) }
    }

    /// Group projected amount by an arbitrary key. `nil` keys are excluded.
    static func remainingForecastGrouped(
        _ subs: [Subscription],
        year: Int,
        from start: Date = Date(),
        key: (Subscription) -> String?
    ) -> [String: Double] {
        var result: [String: Double] = [:]
        for sub in subs {
            guard let k = key(sub) else { continue }
            let amt = projectedAmount(for: sub, in: year, from: start)
            if amt > 0 { result[k, default: 0] += amt }
        }
        return result
    }

    static func remainingForecastByCategory(_ subs: [Subscription], year: Int, from start: Date = Date()) -> [String: Double] {
        remainingForecastGrouped(subs, year: year, from: start) { $0.category }
    }

    static func remainingForecastByList(_ subs: [Subscription], year: Int, from start: Date = Date()) -> [String: Double] {
        remainingForecastGrouped(subs, year: year, from: start) { $0.list }
    }

    static func remainingForecastByPaymentMethod(_ subs: [Subscription], year: Int, from start: Date = Date()) -> [String: Double] {
        remainingForecastGrouped(subs, year: year, from: start) { $0.paymentMethod }
    }

    /// Months remaining in `year` from `start` (inclusive). For past years returns 12; future years returns 12.
    static func monthsRemaining(in year: Int, from start: Date = Date()) -> Int {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: start)
        if year != currentYear { return 12 }
        let currentMonth = calendar.component(.month, from: start)
        return max(1, 13 - currentMonth)
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
