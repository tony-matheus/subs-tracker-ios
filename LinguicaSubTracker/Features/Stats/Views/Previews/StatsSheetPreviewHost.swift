import SwiftUI

struct StatsSheetPreviewHost: View {
    private let store = StatsPreviewData.makeDemoStore()
    private let settingsStore = SettingsStore()

    var body: some View {
        Color.black.ignoresSafeArea()
            .sheet(isPresented: .constant(true)) {
                StatsSheet(store: store, settingsStore: settingsStore)
                    .environment(store)
                    .environment(settingsStore)
            }
    }
}
