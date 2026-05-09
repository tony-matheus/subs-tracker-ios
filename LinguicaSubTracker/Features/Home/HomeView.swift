//
//  HomeView.swift
//  LinguicaSubTracker
//
//  Created by Tony Matheus on 23/04/26.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack {
            TopBar()
            TotalView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            CalendarView()
        }
        .sheet(
            isPresented: Binding(
                get: { store.selectedDay != nil },
                set: { if !$0 { store.selectedDay = nil } }
            )
        ) {
            if let day = store.selectedDay {
                let daySubs = SubscriptionService.subscriptions(for: day, subs: store.filteredSubscriptions)
                if daySubs.isEmpty {
                    SubscriptionListSheet(date: day)
                } else {
                    SubscriptionInDay(date: day)
                }
            }
        }
        .sheet(
            isPresented: Binding(
                get: { store.selectedSubscription != nil },
                set: { if !$0 { store.selectedSubscription = nil } }
            )
        ) {
            if let sub = store.selectedSubscription {
                SubscriptionSummarySheet(subscription: sub)
            }
        }
    }
}

#Preview {
    let calendar = Calendar.current
    func date(_ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 5, day: day))!
    }

    let store = AppStore()
    store.subscriptions = [
        Subscription(name: "Netflix",  price: 15.99, colorHex: "#E50914", schedule: .monthly, startDate: date(4),  category: "Entertainment", list: "Personal"),
        Subscription(name: "Notion",   price: 8.00,  colorHex: "#000000", schedule: .monthly, startDate: date(11), category: "Productivity",  list: "Work"),
        Subscription(name: "iCloud",   price: 2.99,  colorHex: "#007AFF", schedule: .monthly, startDate: date(18), category: "Utilities",     list: "Personal"),
        Subscription(name: "Spotify",  price: 10.99, colorHex: "#1DB954", schedule: .monthly, startDate: date(22), category: "Lifestyle",     list: "Family"),
        Subscription(name: "1Password", price: 4.99, colorHex: "#3B66BC", schedule: .monthly, startDate: date(27), category: "Utilities",     list: "Personal"),
    ]

    return HomeView()
        .environmentObject(store)
        .environmentObject(SettingsStore())
}
