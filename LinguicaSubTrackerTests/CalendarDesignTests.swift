import SwiftUI
import Testing
@testable import LinguicaSubTracker

@Suite("Calendar design and migration")
@MainActor
struct CalendarDesignTests {
    @Test("Legacy settings decode without losing unrelated preferences", arguments: ["rounded", "contrastRounded", "straight", "compact", "bigger", "default", "large", "future"])
    func migration(raw: String) throws {
        var settings = AppSettings.default
        settings.currencyCode = "EUR"
        settings.monthlyBudget = 731
        settings.calendarStyle = .default
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(settings)) as? [String: Any])
        json["calendarStyle"] = raw
        let decoded = try JSONDecoder().decode(AppSettings.self, from: JSONSerialization.data(withJSONObject: json))
        let expected: CalendarStyle = raw == "compact" ? .compact : ["bigger", "large"].contains(raw) ? .large : .default
        #expect(decoded.calendarStyle == expected)
        #expect(decoded.currencyCode == "EUR")
        #expect(decoded.monthlyBudget == 731)
        #expect(decoded.categories.count == settings.categories.count)
        #expect(String(data: try JSONEncoder().encode(expected), encoding: .utf8) == "\"\(expected.rawValue)\"")
        json.removeValue(forKey: "calendarStyle")
        #expect(try JSONDecoder().decode(AppSettings.self, from: JSONSerialization.data(withJSONObject: json)).calendarStyle == nil)
    }

    @Test("Exactly three selectable styles and the Large total range")
    func styles() {
        #expect(CalendarStyle.allCases == [.default, .compact, .large])
        #expect(CalendarStyle.default.dateSize == 12)
        #expect(CalendarStyle.compact.dateSize == 14)
        #expect(CalendarStyle.large.totalSizeRange == 40...72)
    }

    @Test("Four, five and six weeks retain only necessary slots", arguments: [(2, 28), (10, 35), (5, 42)])
    func grid(_ month: Int, _ count: Int) throws {
        let date = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: month, day: 1)))
        let grid = CalendarService.daysGrid(for: date)
        #expect(grid.count == count)
        #expect(grid.suffix(7).contains { $0 != nil })
        #expect(grid.prefix(7).contains { $0 != nil })
        for style in CalendarStyle.allCases {
            let rows = CGFloat(grid.count / 7)
            let height = (style.gridHeight - (rows - 1) * 4) / rows
            #expect(abs(height * rows + (rows - 1) * 4 - style.gridHeight) < 0.001)
        }
    }

    @Test("Indicators never overlap by more than twenty percent", arguments: [5.0, 18.0, 24.0])
    func overlap(size: Double) {
        for width in stride(from: 8.0, through: 100.0, by: 1) {
            let spacing = CalendarIndicatorLayout.spacing(count: 3, size: size, available: width)
            #expect(spacing >= -size * 0.2)
            #expect(spacing <= 2)
        }
    }

    @Test("Narrow Large falls back to Default seals and keeps overflow inline")
    func largeFallback() {
        let layout = CalendarIndicatorLayout.seals(count: 4, style: .large, width: 43, height: 46, textWidth: { _ in 10 }, textHeight: 10)
        #expect(layout.size == 18)
        #expect(layout.visibleCount == 1)
        #expect(layout.overflowCount == 3)
        #expect(!layout.overflowAbove)
        let wide = CalendarIndicatorLayout.seals(count: 4, style: .large, width: 80, height: 46, textWidth: { _ in 10 }, textHeight: 10)
        #expect(wide.size == 24)
        #expect(wide.visibleCount == 2)
        #expect(!wide.overflowAbove)
    }

    @Test("Overflow above Default seals; accessible short cells recount hidden expenses")
    func overflow() {
        let normal = CalendarIndicatorLayout.seals(count: 14, style: .default, width: 43, height: 34, textWidth: { _ in 15 }, textHeight: 10)
        #expect(normal.overflowAbove)
        #expect(normal.overflowCount == 12)
        let accessible = CalendarIndicatorLayout.seals(count: 14, style: .default, width: 43, height: 28, textWidth: { _ in 20 }, textHeight: 20)
        #expect(accessible.visibleCount == 1)
        #expect(accessible.overflowCount == 13)
        #expect(!accessible.overflowAbove)
    }

    @Test("Accessibility overflow fits both the memo height and text compartment")
    func fittedOverflow() {
        let size = CalendarIndicatorLayout.fittedLabelSize(requested: 28, measuredWidth: 53,
                                                          lineHeight: 34, width: 21, height: 12)
        #expect(size <= 28)
        #expect(size / 28 * 53 <= 21)
        #expect(size / 28 * 34 <= 12)
    }

    @Test("Completed today reveal matches its static brush mask")
    func completedReveal() throws {
        let date = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 15)))
        for height in [20.0, 24.0] {
            let size = CGSize(width: 28, height: height)
            let animated = ImageRenderer(content: EnsoReveal(seed: EnsoShape.seed(for: date), size: size, color: .shu, progress: 1))
            let staticMark = ImageRenderer(content: InkBrush(seed: EnsoShape.seed(for: date), size: size, color: .shu))
            animated.scale = 3
            staticMark.scale = 3
            let finalImage = try #require(animated.uiImage?.pngData())
            let staticImage = try #require(staticMark.uiImage?.pngData())
            #expect(finalImage.elementsEqual(staticImage))
        }
    }

    @Test("Brushes are stable, distinct, bounded, and cached")
    func brush() throws {
        let date = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 1)))
        let size = CGSize(width: 28, height: 24)
        var seeds = Set<UInt64>()
        for day in 0..<31 {
            let value = try #require(Calendar.current.date(byAdding: .day, value: day, to: date))
            let seed = EnsoShape.seed(for: value)
            #expect(seed == EnsoShape.seed(for: value.addingTimeInterval(60)))
            seeds.insert(seed)
            let mask = InkBrushRenderer.mask(seed: seed, size: size, scale: 2)
            #expect(mask === InkBrushRenderer.mask(seed: seed, size: size, scale: 2))
            #expect(CGRect(origin: .zero, size: size).contains(mask.bounds))
        }
        #expect(seeds.count == 31)
    }
}
