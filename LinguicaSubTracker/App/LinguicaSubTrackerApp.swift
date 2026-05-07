//
//  SubscriptionTrackerApp.swift
//  LinguicaSubTracker
//
//  Created by Tony Matheus on 23/04/26.
//

import Foundation
import SwiftUI

@main
struct LinguicaSubTrackerApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var settingsStore = SettingsStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.font, Theme.font(size: 16, weight: .regular))
                .environmentObject(store)
                .environmentObject(settingsStore)
        }
    }
}

