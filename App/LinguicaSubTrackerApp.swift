//
//  SubscriptionTrackerApp.swift
//  LinguicaSubTracker
//
//  Created by Tony Matheus on 23/04/26.
//

import Foundation
import SwiftUI

@main
struct LinguicaSubTrackerApp: App{
    @StateObject private var store = AppStore()
    
    var body: some Scene {
        WindowGroup {
            HomeView().environmentObject(store)
        }
    }
}
