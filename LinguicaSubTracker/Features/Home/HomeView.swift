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

#Preview {
    HomeView()
        .environmentObject(PreviewSupport.makeStore())
        .environmentObject(PreviewSupport.makeSettingsStore())
}
