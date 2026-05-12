import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class DayCellViewModel {
    let store: AppStore
    var subscriptions: [Subscription]
    var status: DayStatus
    var date: Date?

    init(store: AppStore, date: Date?, status: DayStatus, subscriptions: [Subscription]) {
        self.store = store
        self.date = date
        self.status = status
        self.subscriptions = subscriptions
    }

    var primarySub: Subscription? { subscriptions.first }
    var secondarySub: Subscription? { subscriptions.last }
    var primaryCustomization: LogoCustomization? {
        primarySub?.logoCustomization(in: store)
    }
    var primaryColor: Color? { primaryCustomization?.resolvedBackground }
    var overflowCount: Int { max(0, subscriptions.count - 2) }
    var displayDay: Bool { status != .none }
    var dayNumber: Int? {
        guard let date else { return nil }
        return Calendar.current.component(.day, from: date)
    }
}
