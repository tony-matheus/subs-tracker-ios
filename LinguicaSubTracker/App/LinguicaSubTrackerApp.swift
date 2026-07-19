//
//  SatoruApp.swift
//  Satoru
//
//  Created by Tony Matheus on 23/04/26.
//

import Foundation
import SwiftUI

@main
struct SatoruApp: App {
    @State private var store = AppStore()
    @State private var settingsStore = SettingsStore()
    @State private var coordinator = AppCoordinator()
    @State private var showOnboarding = !StorageService.hasCompletedOnboarding

    var body: some Scene {
        WindowGroup {
            HomeView(store: store, settingsStore: settingsStore, coordinator: coordinator)
                .environment(\.font, Theme.font(size: 16, weight: .regular))
                .environment(store)
                .environment(settingsStore)
                .environment(coordinator)
                .preferredColorScheme(settingsStore.themeMode.colorScheme)
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView(store: store, settingsStore: settingsStore) {
                        StorageService.hasCompletedOnboarding = true
                        showOnboarding = false
                    }
                    .environment(\.font, Theme.font(size: 16, weight: .regular))
                    .preferredColorScheme(settingsStore.themeMode.colorScheme)
                }
                .onChange(of: coordinator.didRequestOnboardingReplay) { _, requested in
                    guard requested else { return }
                    coordinator.didRequestOnboardingReplay = false
                    showOnboarding = true
                }
        }
    }
}

