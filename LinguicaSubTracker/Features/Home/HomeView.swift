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
                SubscriptionListSheet(date: day)
            }
        }
    }
}

#Preview {
    HomeView().environmentObject(AppStore())
}
