//
//  TotalView.swift
//  LinguicaSubTracker
//
//  Created by Tony Matheus on 23/04/26.
//

import SwiftUI

struct TotalView: View {
    @EnvironmentObject var store: AppStore
    
    var total: Double {
        SubscriptionService.totalForMonth(
            store.subscriptions,
            month: store.currentMonth
        )
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(store.currentMonth.formatted(.dateTime.month().year()))
                .foregroundColor(.gray)

            TextAnimatedView(text: "$ \(total.asPeriodCurrency)", onTapGesture: handleTapGesture)
            
        }
    }
    
    func handleTapGesture () {
        
    }
}

#Preview {
    TotalView().environmentObject(AppStore())
}
