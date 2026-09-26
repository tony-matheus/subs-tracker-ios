import CloudKit
import Foundation
import Testing

@testable import LinguicaSubTracker

@MainActor
private func expense(_ name: String, price: Double = 10, id: UUID = UUID()) -> Expense {
    Expense(id: id, name: name, price: price, billingCycle: .oneTime, type: .expense,
            startDate: Date(timeIntervalSinceReferenceDate: 800_000_000))
}

@MainActor
@Suite("iCloud sync")
struct CloudSyncTests {

    @Test("merge upserts by id, drops deletes, keeps untouched local rows")
    func merge() {
        let kept = expense("Kept")
        let edited = expense("Coffee", price: 4)
        let removed = expense("Gone")
        let incoming = expense("New")
        var editedRemote = edited
        editedRemote.price = 5

        let result = AppStore.merge(
            local: [kept, edited, removed],
            saved: [editedRemote, incoming],
            deleted: [removed.id, UUID()]  // unknown id is a no-op
        )

        #expect(result.map(\.id) == [kept.id, edited.id, incoming.id])
        #expect(result[1].price == 5)
    }

    @Test("expense survives a CKRecord round trip, logo included")
    func expenseRoundTrip() throws {
        let original = expense("Netflix", price: 15.99)
        let logo = LogoCustomization(id: original.id, primaryColorHex: "#E50914", style: .emoji, emoji: "🎬")

        let record = try #require(CloudSyncService.makeExpenseRecord(original, logo: logo))
        #expect(record.recordID.recordName == original.id.uuidString)
        #expect(record.recordID.zoneID == CloudSyncService.zoneID)

        let (decoded, decodedLogo) = try #require(CloudSyncService.decodeExpense(from: record))
        #expect(decoded == original)
        #expect(decodedLogo == logo)
    }

    @Test("expense without a logo round-trips with nil logo")
    func expenseWithoutLogo() throws {
        let original = expense("Rent", price: 1200)
        let record = try #require(CloudSyncService.makeExpenseRecord(original, logo: nil))
        let (decoded, decodedLogo) = try #require(CloudSyncService.decodeExpense(from: record))
        #expect(decoded == original)
        #expect(decodedLogo == nil)
    }

    @Test("settings survive a CKRecord round trip")
    func settingsRoundTrip() throws {
        var settings = AppSettings.default
        settings.currencyCode = "BRL"
        settings.monthlyBudget = 2500
        let record = try #require(CloudSyncService.makeSettingsRecord(settings))
        let decoded = try #require(CloudSyncService.decodeSettings(from: record))
        #expect(decoded.currencyCode == "BRL")
        #expect(decoded.monthlyBudget == 2500)
        #expect(decoded.categories.map(\.name) == settings.categories.map(\.name))
    }
}
