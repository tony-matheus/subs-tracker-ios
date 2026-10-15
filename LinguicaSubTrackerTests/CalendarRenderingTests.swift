import XCTest
import SwiftUI
@testable import LinguicaSubTracker

/// Real-view renders catch clipping at the 375pt minimum phone width. Attachments
/// are kept for visual review, including custom artwork and large overflow counts.
final class CalendarRenderingTests: XCTestCase {
    @MainActor
    func testCalendarVisualMatrix() throws {
        let store = AppStore()
        let calendar = Calendar.current
        let output = FileManager.default.temporaryDirectory.appendingPathComponent("calendar-review")
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        for month in [2, 10, 5] {
            let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: month, day: 1)))
            let grid = CalendarService.daysGrid(for: date)
            let expenses: [[Expense]] = grid.map { value in
                guard let value else { return [] }
                let day = calendar.component(.day, from: value)
                let names = ["Spotify", "Netflix", "Apple Music", "Dropbox", "iCloud", "Coffee", "Transit", "Notion", "Water", "Gym", "Books", "Adobe", "Phone", "Tea"]
                let count = [0, 1, 2, 4, 5, 14][day % 6]
                return names.prefix(count).map { Expense(name: $0, price: 9, billingCycle: .monthly, startDate: value) }
            }
            for style in CalendarStyle.allCases {
                for dark in [false, true] {
                    let view = MonthView(store: store, month: date, grid: grid,
                        expenseCounts: expenses.map(\.count), expenses: expenses, style: style,
                        height: style.gridHeight, onTap: { _ in }, animatesToday: false)
                        .padding(.horizontal, 12)
                        .frame(width: 375, height: style.gridHeight + 60)
                        .background(Color.paper)
                        .environment(\.colorScheme, dark ? .dark : .light)
                    let renderer = ImageRenderer(content: view)
                    renderer.scale = 2
                    let image = try XCTUnwrap(renderer.uiImage)
                    let name = "\(month)-\(style.rawValue)-\(dark ? "dark" : "light")"
                    try image.pngData()?.write(to: output.appendingPathComponent(name + ".png"))
                    let attachment = XCTAttachment(image: image)
                    attachment.name = name
                    attachment.lifetime = .keepAlways
                    add(attachment)
                }
            }
        }
        // First/middle/last date brushes, today's emphasis, and both digit widths.
        for style in CalendarStyle.allCases {
            let view = HStack(spacing: 4) {
                ForEach([1, 15, 31], id: \.self) { day in
                    let date = calendar.date(from: DateComponents(year: 2026, month: 5, day: day))!
                    DayCell(viewModel: DayCellViewModel(store: store, date: date, status: day == 15 ? .current : .normal, expenses: []),
                            style: style, height: (style.gridHeight - 20) / 6, onTap: { _ in }, animatesToday: false)
                        .frame(width: 47)
                }
            }.padding(12).background(Color.paper).environment(\.colorScheme, .light)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 3
            let image = try XCTUnwrap(renderer.uiImage)
            try image.pngData()?.write(to: output.appendingPathComponent("brush-\(style.rawValue).png"))
        }
        let may = calendar.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        let busy = (0..<14).map { Expense(name: "Expense \($0)", price: 1, billingCycle: .monthly, startDate: may) }
        for language in ["en", "fr", "ja"] {
            let view = VStack(spacing: 8) {
                WeekdayBand()
                HStack(spacing: 4) {
                    ForEach(CalendarStyle.allCases) { style in
                        DayCell(viewModel: DayCellViewModel(store: store, date: may, status: .current, expenses: busy),
                                style: style, height: (style.gridHeight - 20) / 6, onTap: { _ in }, animatesToday: false)
                            .frame(width: 47)
                    }
                }
            }
            .padding(12).frame(width: 375).background(Color.paper)
            .environment(\.colorScheme, .dark)
            .environment(\.locale, Locale(identifier: language))
            .environment(\.dynamicTypeSize, .accessibility5)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            let image = try XCTUnwrap(renderer.uiImage)
            let attachment = XCTAttachment(image: image)
            attachment.name = "Accessible-\(language)-dark"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        print("CALENDAR_RENDER_OUTPUT=\(output.path)")
    }
}
