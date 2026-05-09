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
    @State private var showStats = false
    @State private var showSearch = false

    private var listBinding: Binding<String?> {
        Binding(get: { store.filter.list }, set: { store.filter.list = $0 })
    }

    private var categoryBinding: Binding<String?> {
        Binding(get: { store.filter.category }, set: { store.filter.category = $0 })
    }

    private var paymentBinding: Binding<String?> {
        Binding(get: { store.filter.paymentMethod }, set: { store.filter.paymentMethod = $0 })
    }

    private var filterLabel: String {
        let names = store.filter.activeNames
        if names.isEmpty { return "All Subs" }
        if names.count == 1 { return names[0] }
        return "Filtered (\(names.count))"
    }

    var body: some View {
        HStack {
            Menu {
                Button {
                    store.filter = .all
                } label: {
                    if store.filter.isActive {
                        Text("All Subscriptions")
                    } else {
                        Label("All Subscriptions", systemImage: "checkmark")
                    }
                }

                Divider()

                Menu("Lists") {
                    Picker("Lists", selection: listBinding) {
                        Text("All Lists").tag(String?.none)
                        ForEach(settingsStore.settings.lists) { list in
                            Text(list.name).tag(String?.some(list.name))
                        }
                    }
                }

                Menu("Categories") {
                    Picker("Categories", selection: categoryBinding) {
                        Text("All Categories").tag(String?.none)
                        ForEach(settingsStore.settings.categories) { category in
                            Text(category.name).tag(String?.some(category.name))
                        }
                    }
                }

                Menu("Payment Methods") {
                    Picker("Payment Methods", selection: paymentBinding) {
                        Text("All Payments").tag(String?.none)
                        ForEach(settingsStore.settings.paymentMethods) { method in
                            Text(method.name).tag(String?.some(method.name))
                        }
                    }
                }

            } label: {
                HStack(spacing: 4) {
                    Text(filterLabel)
                        .typography(.titleSmall)
                    Image(systemName: store.filter.isActive ? "line.3.horizontal.decrease.circle.fill" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.gray)
            }

            Spacer()

            HStack(spacing: 16) {
                Button {
                    showSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .iconStyle()
                }

                Button {
                    showStats = true
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
        .fullScreenCover(isPresented: $showSearch) {
            SearchFlow()
                .environmentObject(store)
                .environmentObject(settingsStore)
        }
        .sheet(isPresented: $showStats) {
            StatsSheet()
                .environmentObject(settingsStore)
                .environmentObject(store)
                .presentationDetents([.height(550)])
                .presentationDragIndicator(.visible)
                .presentationBackground {
                    Rectangle()
                        .fill(.ultraThickMaterial)
                        .opacity(0.8)
                }
        }
    }
}
