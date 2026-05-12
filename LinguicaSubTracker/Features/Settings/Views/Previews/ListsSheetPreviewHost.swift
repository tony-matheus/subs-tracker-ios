import SwiftUI

struct ListsSheetPreviewHost: View {
    private let settingsStore = SettingsPreviewData.makeSettingsStore()

    var body: some View {
        Color.black.ignoresSafeArea()
            .sheet(isPresented: .constant(true)) {
                ListsSheet(settingsStore: settingsStore)
            }
    }
}
