import Foundation

enum ExpenseService {

    /// Whole days between two dates, normalized to start-of-day.
    private static func dayCount(from start: Date, to end: Date) -> Int {
        let calendar = Calendar.current
        let a = calendar.startOfDay(for: start)
        let b = calendar.startOfDay(for: end)
        return calendar.dateComponents([.day], from: a, to: b).day ?? 0
    }

    static func isActive(on date: Date, expense: Expense) -> Bool {
        let calendar = Calendar.current

        if !expense.isActive {
            return false
        }

        if let endDate = expense.endDate,
           calendar.startOfDay(for: date) > calendar.startOfDay(for: endDate) {
            return false
        }

        if calendar.startOfDay(for: date) < calendar.startOfDay(for: expense.startDate) {
            return false
        }

        switch expense.billingCycle {

        case .oneTime:
            return calendar.isDate(date, inSameDayAs: expense.startDate)

        case .biWeekly:
            let days = dayCount(from: expense.startDate, to: date)
            return days >= 0 && days % 14 == 0

        case .monthly:
            return calendar.component(.day, from: date)
                == calendar.component(.day, from: expense.startDate)

        case .yearly:
            return calendar.component(.month, from: date)
                == calendar.component(.month, from: expense.startDate)
            && calendar.component(.day, from: date)
                == calendar.component(.day, from: expense.startDate)
        }
    }

    static func expenses(for date: Date, expenses: [Expense]) -> [Expense] {
        expenses.filter { isActive(on: date, expense: $0) }
    }


    static func nextPayment(for expense: Expense, from today: Date = Date()) -> Date? {
        guard expense.isActive else { return nil }
        let calendar = Calendar.current

        var candidate: Date
        switch expense.billingCycle {
        case .oneTime:
            // Single charge: only "upcoming" if the start date is still ahead.
            if calendar.startOfDay(for: expense.startDate) <= calendar.startOfDay(for: today) {
                return nil
            }
            candidate = expense.startDate

        case .biWeekly:
            let start = calendar.startOfDay(for: expense.startDate)
            let day = calendar.startOfDay(for: today)
            if start > day {
                candidate = start
            } else {
                let days = dayCount(from: start, to: day)
                let periodsElapsed = days / 14
                let next = calendar.date(byAdding: .day, value: (periodsElapsed + 1) * 14, to: start) ?? start
                candidate = next
            }

        case .monthly:
            let startDay = calendar.component(.day, from: expense.startDate)
            var components = calendar.dateComponents([.year, .month], from: today)
            components.day = startDay
            guard var base = calendar.date(from: components) else { return nil }
            if base <= today {
                base = calendar.date(byAdding: .month, value: 1, to: base) ?? base
            }
            candidate = base

        case .yearly:
            let startMonth = calendar.component(.month, from: expense.startDate)
            let startDay   = calendar.component(.day,   from: expense.startDate)
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

        if let end = expense.endDate, candidate > end { return nil }
        return candidate
    }


    static func totalSpent(for expense: Expense, until today: Date = Date()) -> Double {
        guard today >= expense.startDate else { return 0 }
        let calendar = Calendar.current
        var count = 0

        let cap = expense.endDate.map { min(today, $0) } ?? today

        switch expense.billingCycle {
        case .oneTime:
            count = 1

        case .biWeekly:
            let days = dayCount(from: expense.startDate, to: cap)
            count = max(0, days / 14) + 1

        case .monthly:
            let months = calendar.dateComponents([.month], from: expense.startDate, to: cap).month ?? 0
            count = months + 1

        case .yearly:
            let years = calendar.dateComponents([.year], from: expense.startDate, to: cap).year ?? 0
            count = years + 1
        }

        return Double(max(count, 0)) * expense.price
    }



    /// Number of remaining payments of `exp` between `start` and end-of-`year` (inclusive).
    static func remainingPaymentCount(
        for exp: Expense,
        in year: Int,
        from start: Date = Date()
    ) -> Int {
        guard exp.isActive else { return 0 }
        let calendar = Calendar.current
        guard let endOfYear = calendar.date(from: DateComponents(year: year, month: 12, day: 31, hour: 23, minute: 59, second: 59)),
              let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1))
        else { return 0 }

        let windowStart = max(start, startOfYear, exp.startDate)
        let windowEnd = exp.endDate.map { min(endOfYear, $0) } ?? endOfYear
        if windowStart > windowEnd { return 0 }

        switch exp.billingCycle {
        case .oneTime:
            return (exp.startDate >= windowStart && exp.startDate <= windowEnd) ? 1 : 0

        case .biWeekly:
            // Count 14-day occurrences from startDate that fall within the window.
            var count = 0
            var cursor = calendar.startOfDay(for: exp.startDate)
            // Fast-forward to the first occurrence >= windowStart.
            if cursor < calendar.startOfDay(for: windowStart) {
                let days = dayCount(from: cursor, to: windowStart)
                let periods = Int(ceil(Double(days) / 14.0))
                cursor = calendar.date(byAdding: .day, value: periods * 14, to: cursor) ?? cursor
            }
            while cursor <= windowEnd {
                if cursor >= calendar.startOfDay(for: windowStart) { count += 1 }
                cursor = calendar.date(byAdding: .day, value: 14, to: cursor) ?? windowEnd.addingTimeInterval(1)
            }
            return count

        case .monthly:
            let payDay = calendar.component(.day, from: exp.startDate)
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
            let month = calendar.component(.month, from: exp.startDate)
            let day = calendar.component(.day, from: exp.startDate)
            guard let payDate = calendar.date(from: DateComponents(year: year, month: month, day: day)) else { return 0 }
            return (payDate >= windowStart && payDate <= windowEnd) ? 1 : 0
        }
    }

    /// Total $ for `exp` from `start` through end-of-`year`.
    static func projectedAmount(
        for exp: Expense,
        in year: Int,
        from start: Date = Date()
    ) -> Double {
        Double(remainingPaymentCount(for: exp, in: year, from: start)) * exp.price
    }

    /// Aggregate projected amount across `expenses`.
    static func remainingForecast(
        _ expenses: [Expense],
        year: Int,
        from start: Date = Date()
    ) -> Double {
        expenses.reduce(0) { $0 + projectedAmount(for: $1, in: year, from: start) }
    }

    /// Group projected amount by an arbitrary key. `nil` keys are excluded.
    static func remainingForecastGrouped(
        _ expenses: [Expense],
        year: Int,
        from start: Date = Date(),
        key: (Expense) -> String?
    ) -> [String: Double] {
        var result: [String: Double] = [:]
        for exp in expenses {
            guard let k = key(exp) else { continue }
            let amt = projectedAmount(for: exp, in: year, from: start)
            if amt > 0 { result[k, default: 0] += amt }
        }
        return result
    }

    static func remainingForecastByCategory(_ expenses: [Expense], year: Int, from start: Date = Date()) -> [String: Double] {
        remainingForecastGrouped(expenses, year: year, from: start) { $0.category }
    }

    static func remainingForecastByList(_ expenses: [Expense], year: Int, from start: Date = Date()) -> [String: Double] {
        remainingForecastGrouped(expenses, year: year, from: start) { $0.list }
    }

    static func remainingForecastByPaymentMethod(_ expenses: [Expense], year: Int, from start: Date = Date()) -> [String: Double] {
        remainingForecastGrouped(expenses, year: year, from: start) { $0.paymentMethod }
    }

    /// Months remaining in `year` from `start` (inclusive). For past years returns 12; future years returns 12.
    static func monthsRemaining(in year: Int, from start: Date = Date()) -> Int {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: start)
        if year != currentYear { return 12 }
        let currentMonth = calendar.component(.month, from: start)
        return max(1, 13 - currentMonth)
    }


    static func totalForMonth(_ expenses: [Expense], month: Date) -> Double {
        let calendar = Calendar.current

        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstOfMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: month)
              )
        else { return 0 }

        var total: Double = 0

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                let activeExpenses = self.expenses(for: date, expenses: expenses)

                total += activeExpenses.reduce(0) { $0 + $1.price }
            }
        }

        return total
    }
}
