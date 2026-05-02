//
//  CalendarService.swift
//  LinguicaSubTracker
//
//  Created by Tony Matheus on 24/04/26.
//

import Foundation

enum WeekStartDay {
    case monday
    case sunday

    var calendarValue: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        }
    }
}

enum CalendarService {
    static func generateMonths() -> [Date] {
        let calendar = Calendar.current
        let now = Date()

        return (-6...6).compactMap {
            calendar.date(byAdding: .month, value: $0, to: now)
        }
    }

    static func daysGrid(
        for date: Date,
        startingOn weekStart: WeekStartDay = .sunday
    ) -> [Date?] {

        var calendar = Calendar.current
        calendar.firstWeekday = weekStart.calendarValue

        guard
            let range = calendar.range(of: .day, in: .month, for: date),
            let firstOfMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: date)
            )
        else { return [] }

        let weekday = calendar.component(.weekday, from: firstOfMonth)

        // convert to 0-based offset depending on week start
        let rawOffset = weekday - calendar.firstWeekday
        let offset = (rawOffset + 7) % 7

        var grid: [Date?] = Array(repeating: nil, count: offset)

        for day in range {
            if let dayDate = calendar.date(
                byAdding: .day,
                value: day - 1,
                to: firstOfMonth
            ) {
                grid.append(dayDate)
            }
        }

        while grid.count % 7 != 0 {
            grid.append(nil)
        }

        return grid
    }
}
