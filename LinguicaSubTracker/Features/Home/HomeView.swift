//
//  HomeView.swift
//  LinguicaSubTracker
//
//  Created by Tony Matheus on 23/04/26.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settingsStore: SettingsStore

    @State private var showAddSheet = false

    private var isOnCurrentMonth: Bool {
        Calendar.current.isDate(store.currentMonth, equalTo: Date(), toGranularity: .month)
    }

    var body: some View {
        VStack {
            TopBar()
            TotalView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            CalendarView()
            HomeActionButton(
                isOnCurrentMonth: isOnCurrentMonth,
                onAdd: { showAddSheet = true },
                onBackToCurrent: jumpToCurrentMonth
            )

        }
        .sheet(isPresented: $showAddSheet) {
            SubscriptionListSheet(date: Date())
                .environmentObject(store)
                .environmentObject(settingsStore)
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

    private func jumpToCurrentMonth() {
        store.rewindRequest = (store.rewindRequest ?? 0) + 1
    }
}

private func makePreviewStore() -> AppStore {
    let calendar = Calendar.current
    let now = Date()
    let monthStart = calendar.date(
        from: calendar.dateComponents([.year, .month], from: now)
    ) ?? now
    func day(_ d: Int) -> Date {
        calendar.date(byAdding: .day, value: d - 1, to: monthStart) ?? monthStart
    }
    let store = AppStore()
    store.subscriptions = [
        Subscription(name: "Netflix",  price: 15.99, colorHex: "#E50914", schedule: .monthly, startDate: day(4),  category: "Entertainment", list: "Personal"),
        Subscription(name: "Notion",   price: 8.00,  colorHex: "#000000", schedule: .monthly, startDate: day(11), category: "Productivity",  list: "Work"),
        Subscription(name: "iCloud",   price: 2.99,  colorHex: "#007AFF", schedule: .monthly, startDate: day(18), category: "Utilities",     list: "Personal"),
        Subscription(name: "Spotify",  price: 10.99, colorHex: "#1DB954", schedule: .monthly, startDate: day(22), category: "Lifestyle",     list: "Family"),
        Subscription(name: "1Password", price: 4.99, colorHex: "#3B66BC", schedule: .monthly, startDate: day(27), category: "Utilities",     list: "Personal"),
    ]
    return store
}

#Preview {
    HomeView()
        .environmentObject(makePreviewStore())
        .environmentObject(SettingsStore())
}
