import XCTest

final class CalendarNavigationTests: XCTestCase {
    @MainActor
    func testMonthHeaderPickerPagingAndList() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-has_completed_onboarding", "YES", "-AppleLanguages", "(en)", "-AppleLocale", "en_CA"]
        app.launchEnvironment["DEBUG_OPEN_SETTINGS_PAGE"] = "calendarstyle"
        app.launch()
        let next = app.buttons["Next month"]
        XCTAssertTrue(next.waitForExistence(timeout: 15))
        next.tap()
        let today = app.buttons["Today"]
        XCTAssertTrue(today.waitForExistence(timeout: 5))
        today.tap()
        XCTAssertTrue(app.buttons["Add expense"].waitForExistence(timeout: 5))
        let month = Date().formatted(.dateTime.month(.wide).year())
        app.buttons[month].tap()
        XCTAssertTrue(app.navigationBars["Jump to Month"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        app.buttons["Switch to list view"].tap()
        XCTAssertTrue(app.buttons["Next month"].exists)
        XCTAssertEqual(app.buttons.matching(identifier: month).count, 1)
        app.buttons["Switch to calendar view"].tap()
        app.swipeUp()
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Home-small-phone-calendar"
        attachment.lifetime = .keepAlways
        add(attachment)
        // Verify vertical scrolling reaches the last date on a short phone.
        let last = Calendar.current.range(of: .day, in: .month, for: Date())!.count
        let day = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
        let lastDate = Calendar.current.date(byAdding: .day, value: last - 1, to: day)!
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: lastDate)
        let lastButton = app.buttons["calendar-day-\(parts.year!)-\(parts.month!)-\(parts.day!)"]
        if !lastButton.isHittable { print(app.debugDescription) }
        XCTAssertTrue(lastButton.isHittable)
        for style in ["large", "compact", "default"] {
            app.buttons["Settings"].tap()
            let option = app.buttons["calendar-style-\(style)"]
            XCTAssertTrue(option.waitForExistence(timeout: 5))
            XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "calendar-style-")).count, 3)
            option.tap()
            if style == "default" {
                let settings = XCTAttachment(screenshot: app.screenshot())
                settings.name = "Calendar-styles-dark"
                settings.lifetime = .keepAlways
                add(settings)
            }
            app.buttons["Close calendar styles"].tap()
            app.navigationBars["Settings"].buttons.firstMatch.tap()
            app.swipeUp()
            XCTAssertTrue(lastButton.isHittable)
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = "Home-\(style)-dark"
            shot.lifetime = .keepAlways
            add(shot)
        }
    }
}
