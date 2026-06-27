import SwiftUI

struct ExpenseTemplateSheetPreviewHost: View {
    private let store = ExpensePreviewData.makeStore()
    private let settingsStore = ExpensePreviewData.makeSettingsStore()

    var body: some View {
        ExpenseTemplateSheet(date: Date(), store: store, settingsStore: settingsStore)
    }
}
