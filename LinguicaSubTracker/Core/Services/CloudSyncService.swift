import CloudKit
import Foundation
import Observation
import os

/// iCloud sync for expenses, logos and settings, built on `CKSyncEngine`.
///
/// The local JSON/UserDefaults store stays the source of truth: stores tell
/// this service which ids changed, the engine asks for the records when it's
/// ready to send, and fetched changes are applied back through
/// `AppStore.applyRemote` / `SettingsStore.applyRemote` (which don't echo).
///
/// Payloads are JSON blobs, not per-field CloudKit schema — one `Expense`
/// record per expense (recordName = expense UUID, logo as a `CKAsset` since
/// photo logos can outgrow the 1MB record cap), plus one `Settings` record.
@Observable
@MainActor
final class CloudSyncService: CKSyncEngineDelegate {
    /// Same key the Settings toggle writes via `@AppStorage`.
    static let enabledKey = "icloud_sync_enabled"
    static let containerID = "iCloud.com.dtx.LinguicaSubTracker"
    static let zoneID = CKRecordZone.ID(zoneName: "Satoru")
    static let settingsRecordName = "app-settings"
    private static let stateKey = "ck_sync_state"
    private static let systemFieldsKey = "ck_system_fields"
    private static let log = Logger(subsystem: "Satoru", category: "CloudSync")

    /// Pill message for `SyncToast`; set when fetched changes touch local data.
    var toast: String?

    @ObservationIgnored private let store: AppStore
    @ObservationIgnored private let settingsStore: SettingsStore
    @ObservationIgnored private var engine: CKSyncEngine?
    /// Archived CKRecord system fields (change tag etc.) by recordName, so
    /// saves update the server copy instead of colliding with it.
    @ObservationIgnored private var systemFields: [String: Data]

    var isEnabled: Bool { UserDefaults.standard.bool(forKey: Self.enabledKey) }

    init(store: AppStore, settingsStore: SettingsStore) {
        self.store = store
        self.settingsStore = settingsStore
        systemFields = UserDefaults.standard.dictionary(forKey: Self.systemFieldsKey) as? [String: Data] ?? [:]
        if isEnabled { startEngine() }
    }

    // MARK: - Public API

    /// Idempotent: the Settings toggle and app reset can both call it.
    func setEnabled(_ on: Bool) {
        UserDefaults.standard.set(on, forKey: Self.enabledKey)
        guard on != (engine != nil) else { return }
        if on {
            resetLocalSyncState()
            startEngine()
            queueFullUpload()
        } else {
            stopEngine()
            resetLocalSyncState()
        }
    }

    func expensesChanged(saved: [UUID], deleted: [UUID]) {
        guard let engine else { return }
        engine.state.add(pendingRecordZoneChanges:
            saved.map { .saveRecord(Self.recordID(for: $0)) }
            + deleted.map { .deleteRecord(Self.recordID(for: $0)) }
        )
    }

    func settingsChanged() {
        engine?.state.add(pendingRecordZoneChanges: [.saveRecord(Self.settingsRecordID)])
    }

    /// Silent fetch-then-send, called when the app becomes active.
    func syncNow() async {
        guard let engine else { return }
        do {
            try await engine.fetchChanges()
            try await engine.sendChanges()
        } catch {
            Self.log.error("syncNow failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Engine lifecycle

    private func startEngine() {
        let state = UserDefaults.standard.data(forKey: Self.stateKey)
            .flatMap { try? JSONDecoder().decode(CKSyncEngine.State.Serialization.self, from: $0) }
        let config = CKSyncEngine.Configuration(
            database: CKContainer(identifier: Self.containerID).privateCloudDatabase,
            stateSerialization: state,
            delegate: self
        )
        engine = CKSyncEngine(config)
    }

    private func stopEngine() {
        guard let old = engine else { return }
        engine = nil
        Task { await old.cancelOperations() }
    }

    /// Forgets the engine state and change tags; local data is untouched.
    private func resetLocalSyncState() {
        UserDefaults.standard.removeObject(forKey: Self.stateKey)
        systemFields = [:]
        persistSystemFields()
    }

    /// Initial upload: the zone, every local expense, and settings.
    private func queueFullUpload() {
        guard let engine else { return }
        engine.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: Self.zoneID))])
        expensesChanged(saved: store.expenses.map(\.id), deleted: [])
        settingsChanged()
    }

    // MARK: - CKSyncEngineDelegate

    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        // Ignore stragglers from an engine that was torn down by the toggle.
        guard syncEngine === engine else { return }

        switch event {
        case .stateUpdate(let update):
            if let data = try? JSONEncoder().encode(update.stateSerialization) {
                UserDefaults.standard.set(data, forKey: Self.stateKey)
            }

        case .accountChange(let change):
            switch change.changeType {
            case .signIn:
                queueFullUpload()
            case .signOut, .switchAccounts:
                // Keep local data; start clean against whatever account is next.
                stopEngine()
                resetLocalSyncState()
                startEngine()
            }

        case .fetchedDatabaseChanges(let changes):
            // Zone wiped server-side (e.g. user cleared iCloud data): drop the
            // stale change tags so the next saves recreate records.
            if changes.deletions.contains(where: { $0.zoneID == Self.zoneID }) {
                systemFields = [:]
                persistSystemFields()
            }

        case .fetchedRecordZoneChanges(let changes):
            applyFetched(changes)

        case .sentRecordZoneChanges(let sent):
            handleSent(sent, engine: syncEngine)

        default:
            break
        }
    }

    func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        let pending = syncEngine.state.pendingRecordZoneChanges.filter { context.options.scope.contains($0) }
        return await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: pending) { recordID in
            await self.recordToSend(recordID, engine: syncEngine)
        }
    }

    // MARK: - Fetch / send handling

    private func applyFetched(_ changes: CKSyncEngine.Event.FetchedRecordZoneChanges) {
        var saved: [Expense] = []
        var logos: [UUID: LogoCustomization] = [:]
        var remoteSettings: AppSettings?

        for modification in changes.modifications {
            let record = modification.record
            cacheSystemFields(of: record)
            if record.recordID.recordName == Self.settingsRecordName {
                remoteSettings = Self.decodeSettings(from: record)
            } else if let (expense, logo) = Self.decodeExpense(from: record) {
                saved.append(expense)
                logos[expense.id] = logo
            }
        }

        var deleted: [UUID] = []
        for deletion in changes.deletions {
            systemFields[deletion.recordID.recordName] = nil
            if let id = UUID(uuidString: deletion.recordID.recordName) { deleted.append(id) }
        }
        persistSystemFields()

        let result = store.applyRemote(saved: saved, logos: logos, deleted: deleted)
        let settingsChanged = remoteSettings.map { settingsStore.applyRemote($0) } ?? false

        if result.inserted > 0 {
            toast = result.inserted == 1 ? "1 new transaction synced" : "\(result.inserted) new transactions synced"
        } else if result.changed > 0 || settingsChanged {
            toast = "Synced from your other device"
        }
    }

    private func handleSent(_ sent: CKSyncEngine.Event.SentRecordZoneChanges, engine: CKSyncEngine) {
        sent.savedRecords.forEach(cacheSystemFields)
        sent.deletedRecordIDs.forEach { systemFields[$0.recordName] = nil }

        var retry: [CKSyncEngine.PendingRecordZoneChange] = []
        for failure in sent.failedRecordSaves {
            let id = failure.record.recordID
            switch failure.error.code {
            case .serverRecordChanged:
                guard let server = failure.error.serverRecord else { continue }
                cacheSystemFields(of: server)
                if id.recordName == Self.settingsRecordName {
                    // Settings: server wins, so a new device adopts the
                    // existing categories/budget instead of overwriting them.
                    if let settings = Self.decodeSettings(from: server) {
                        _ = settingsStore.applyRemote(settings)
                    }
                } else {
                    // ponytail: expenses are client-wins (same row edited on two
                    // devices at once is rare); add `updatedAt` for true LWW.
                    retry.append(.saveRecord(id))
                }
            case .zoneNotFound:
                engine.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: Self.zoneID))])
                systemFields[id.recordName] = nil
                retry.append(.saveRecord(id))
            case .unknownItem:
                // Record gone server-side but still local: recreate it.
                systemFields[id.recordName] = nil
                retry.append(.saveRecord(id))
            default:
                Self.log.error("save \(id.recordName) failed: \(failure.error.localizedDescription)")
            }
        }
        persistSystemFields()
        if !retry.isEmpty { engine.state.add(pendingRecordZoneChanges: retry) }
    }

    /// Builds the outgoing record, or drops the pending change when the item
    /// no longer exists locally (deleted before the engine got to it).
    private func recordToSend(_ recordID: CKRecord.ID, engine: CKSyncEngine) -> CKRecord? {
        let existing = systemFields[recordID.recordName].flatMap(Self.record(fromSystemFields:))
        let record: CKRecord?
        if recordID.recordName == Self.settingsRecordName {
            record = Self.makeSettingsRecord(settingsStore.settings, existing: existing)
        } else if let id = UUID(uuidString: recordID.recordName),
                  let expense = store.expenses.first(where: { $0.id == id }) {
            record = Self.makeExpenseRecord(expense, logo: store.logoCustomizations[id], existing: existing)
        } else {
            record = nil
        }
        if record == nil {
            engine.state.remove(pendingRecordZoneChanges: [.saveRecord(recordID)])
        }
        return record
    }

    // MARK: - System fields cache

    private func cacheSystemFields(of record: CKRecord) {
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        record.encodeSystemFields(with: coder)
        coder.finishEncoding()
        systemFields[record.recordID.recordName] = coder.encodedData
    }

    private func persistSystemFields() {
        UserDefaults.standard.set(systemFields, forKey: Self.systemFieldsKey)
    }

    private static func record(fromSystemFields data: Data) -> CKRecord? {
        guard let coder = try? NSKeyedUnarchiver(forReadingFrom: data) else { return nil }
        coder.requiresSecureCoding = true
        defer { coder.finishDecoding() }
        return CKRecord(coder: coder)
    }

    // MARK: - Record mapping (static so tests can round-trip without an engine)

    static let settingsRecordID = CKRecord.ID(recordName: settingsRecordName, zoneID: zoneID)

    static func recordID(for id: UUID) -> CKRecord.ID {
        CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
    }

    static func makeExpenseRecord(
        _ expense: Expense,
        logo: LogoCustomization?,
        existing: CKRecord? = nil
    ) -> CKRecord? {
        guard let payload = try? JSONEncoder().encode(expense) else { return nil }
        let record = existing ?? CKRecord(recordType: "Expense", recordID: recordID(for: expense.id))
        record["payload"] = payload
        if let logo, let data = try? JSONEncoder().encode(logo) {
            // ponytail: temp files are left for the OS to purge; CloudKit
            // copies them on upload.
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("ck-logo-\(expense.id.uuidString).json")
            guard (try? data.write(to: url)) != nil else { return nil }
            record["logo"] = CKAsset(fileURL: url)
        } else {
            record["logo"] = nil
        }
        return record
    }

    static func decodeExpense(from record: CKRecord) -> (Expense, LogoCustomization?)? {
        guard let payload = record["payload"] as? Data,
              let expense = try? JSONDecoder().decode(Expense.self, from: payload)
        else { return nil }
        let logo = (record["logo"] as? CKAsset)?.fileURL
            .flatMap { try? Data(contentsOf: $0) }
            .flatMap { try? JSONDecoder().decode(LogoCustomization.self, from: $0) }
        return (expense, logo)
    }

    static func makeSettingsRecord(_ settings: AppSettings, existing: CKRecord? = nil) -> CKRecord? {
        guard let payload = try? JSONEncoder().encode(settings) else { return nil }
        let record = existing ?? CKRecord(recordType: "Settings", recordID: settingsRecordID)
        record["payload"] = payload
        return record
    }

    static func decodeSettings(from record: CKRecord) -> AppSettings? {
        (record["payload"] as? Data).flatMap { try? JSONDecoder().decode(AppSettings.self, from: $0) }
    }
}
