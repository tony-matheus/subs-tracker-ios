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
                let daySubs = SubscriptionService.subscriptions(for: day, subs: store.subscriptions)
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
    HomeView().environmentObject(AppStore())
}
