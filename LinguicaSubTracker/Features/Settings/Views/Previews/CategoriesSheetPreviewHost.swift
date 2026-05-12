import SwiftUI

struct CategoriesSheetPreviewHost: View {
    private let settingsStore = SettingsPreviewData.makeSettingsStore()

    var body: some View {
        Color.black.ignoresSafeArea()
            .sheet(isPresented: .constant(true)) {
                CategoriesSheet(settingsStore: settingsStore)
            }
    }
}
