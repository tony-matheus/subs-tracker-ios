import Foundation
import Testing

@testable import LinguicaSubTracker

@Suite("Save & Add another")
@MainActor
struct ExpenseFormResetTests {

    @Test("commitStayingOpen persists, skips onCommit, and resets the form")
    func commitStayingOpen() {
        let store = AppStore()
        let countBefore = store.expenses.count
        var onCommitFired = false

        let vm = ExpenseFormViewModel(
            mode: .createBlank(name: "Safeway", date: .now),
            store: store,
            settingsStore: SettingsStore(),
            onCommit: { _ in onCommitFired = true }
        )
        vm.price = 12.50
        let firstID = vm.customization.id

        #expect(vm.commitStayingOpen())

        #expect(store.expenses.count == countBefore + 1)
        #expect(store.expenses.last?.name == "Safeway")
        // onCommit dismisses the sheet in the hub — must NOT fire here.
        #expect(!onCommitFired)
        // Form is blank and ready for the next entry, with a fresh identity.
        #expect(vm.name.isEmpty)
        #expect(vm.price == 0)
        #expect(vm.customization.id != firstID)

        // Invalid form → no save, no reset.
        #expect(!vm.commitStayingOpen())
        #expect(store.expenses.count == countBefore + 1)

        // Cleanup: don't pollute the simulator's stored expenses.
        if let added = store.expenses.last, added.name == "Safeway" {
            store.delete(added)
        }
    }
}
