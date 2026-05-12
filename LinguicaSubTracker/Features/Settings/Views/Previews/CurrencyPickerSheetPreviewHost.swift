import SwiftUI

struct CurrencyPickerSheetPreviewHost: View {
    private let settingsStore = SettingsPreviewData.makeSettingsStore()

    var body: some View {
        Color.black.ignoresSafeArea()
            .sheet(isPresented: .constant(true)) {
                CurrencyPickerSheet(settingsStore: settingsStore)
            }
    }
}
