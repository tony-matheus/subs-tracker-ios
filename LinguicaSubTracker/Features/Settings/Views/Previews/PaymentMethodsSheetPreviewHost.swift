import SwiftUI

struct PaymentMethodsSheetPreviewHost: View {
    private let settingsStore = SettingsPreviewData.makeSettingsStore()

    var body: some View {
        Color.black.ignoresSafeArea()
            .sheet(isPresented: .constant(true)) {
                PaymentMethodsSheet(settingsStore: settingsStore)
            }
    }
}
