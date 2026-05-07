//
//  TopBar.swift
//  LinguicaSubTracker
//
//  Created by Tony Matheus on 23/04/26.
//

import SwiftUI

struct TopBar: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var store: AppStore

    @State private var showSettings = false

    var body: some View {
        HStack {
            Menu {
                Button("All Subscriptions") {}
                Button("Active") {}
            } label: {
                HStack(spacing: 4) {
                    Text("All Subs")
                        .typography(.titleSmall)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.gray)
            }

            Spacer()

            HStack(spacing: 16) {
                Button {
                    print("Search Tapped")
                } label: {
                    Image(systemName: "magnifyingglass")
                        .iconStyle()
                }

                Button {
                    print("Stats Tapped")
                } label: {
                    Image(systemName: "chart.bar")
                        .iconStyle()
                }

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .iconStyle()
                }
            }
        }
        .padding()
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(settingsStore)
                .environmentObject(store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}
