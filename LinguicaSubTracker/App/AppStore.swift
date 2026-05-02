//
//  AppStore.swift
//  LinguicaSubTracker
//
//  Created by Tony Matheus on 23/04/26.
//

import Foundation
import SwiftUI
import Combine

final class AppStore: ObservableObject {
    @Published var selectedDay: Date?
    @Published var currentMonthIndex: Int = 0
    @Published var subscriptions: [Subscription] = []
    @Published var currentMonth: Date = Date()
    
    init() {
        subscriptions = StorageService.load()
    }
    
    func add(_ subscription: Subscription) {
        subscriptions.append(subscription)
        StorageService.save(subscriptions)
    }
}
