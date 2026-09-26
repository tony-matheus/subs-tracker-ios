//
//  SatoruApp.swift
//  Satoru
//
//  Created by Tony Matheus on 23/04/26.
//

import Foundation
import AppIntents
import SwiftUI

@main
struct SatoruApp: App {
    @State private var store: AppStore
    @State private var settingsStore: SettingsStore
    @State private var sync: CloudSyncService
    @State private var coordinator = AppCoordinator()
    @State private var showOnboarding = !StorageService.hasCompletedOnboarding
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let store = AppStore()
        let settingsStore = SettingsStore()
        let sync = CloudSyncService(store: store, settingsStore: settingsStore)
        store.sync = sync
        settingsStore.sync = sync
        _store = State(initialValue: store)
        _settingsStore = State(initialValue: settingsStore)
        _sync = State(initialValue: sync)
        // Siri/Shortcuts intents get the same live stores via @Dependency.
        AppDependencyManager.shared.add(dependency: store)
        AppDependencyManager.shared.add(dependency: settingsStore)
    }

    var body: some Scene {
        WindowGroup {
            HomeView(store: store, settingsStore: settingsStore, coordinator: coordinator)
                .environment(\.font, Theme.font(size: 16, weight: .regular))
                .environment(store)
                .environment(settingsStore)
                .environment(coordinator)
                .overlay { SyncToast(message: $sync.toast) }
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
                .onChange(of: scenePhase) { _, phase in
                    // Silent pull on every open; the pill reports anything new.
                    if phase == .active { Task { await sync.syncNow() } }
                }
        }
    }
}
