import Foundation
import Observation
import SwiftUI
import UIKit

/// Hidden hold-to-speak capture on the Home screen. Drives the blur overlay,
/// the recording button state, and the live expense list that grows upward
/// from the button as speech is recognized.
///
/// Live parsing: on every transcript update the full text is re-parsed
/// (deterministic regex path — fast, on-device). All segments except the
/// last are final ("frozen") and appended once; the last segment keeps
/// updating its row in place until a new segment starts or recording stops.
@Observable
@MainActor
final class VoiceCaptureViewModel {

    var isActive = false
    var isRecording = false
    var isProcessing = false
    var transcript = ""
    var items: [ParsedExpense] = []
    var errorMessage: String?
    var micDenied = false

    /// Smoothed 0…1 mic level for the waveform ring.
    var level: Float = 0

    let store: AppStore
    let settingsStore: SettingsStore

    private let transcription = SpeechTranscriptionService()
    private var startTask: Task<Void, Never>?
    /// Generation counter: bumped on every begin/dismiss so in-flight async
    /// work from a previous hold can never resurrect state after dismissal.
    private var session = 0
    /// Segments of the current utterance already appended as final rows.
    private var frozenCount = 0
    /// Row currently being updated by the still-growing last segment.
    private var growingID: UUID?

    init(store: AppStore, settingsStore: SettingsStore) {
        self.store = store
        self.settingsStore = settingsStore
    }

    private var categoryNames: [String] {
        settingsStore.settings.categories.map(\.name)
    }

    var currencySymbol: String {
        MoneyFormatter.symbol(for: settingsStore.settings.currencyCode)
    }

    // MARK: - Hold to speak

    func beginHold() {
        guard !isRecording, !isProcessing, startTask == nil else { return }
        session += 1
        let generation = session
        isActive = true
        errorMessage = nil
        transcript = ""
        frozenCount = 0
        growingID = nil

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        startTask = Task {
            do {
                try await transcription.start(
                    onUpdate: { [weak self] text in self?.liveParse(text) },
                    onLevel: { [weak self] raw in
                        guard let self else { return }
                        // Attack fast, decay slow — calm, not jittery.
                        let normalized = min(1, raw * 9)
                        level = max(normalized, level * 0.82)
                    }
                )
                guard generation == self.session else {
                    // Dismissed while starting — don't leave the mic running.
                    _ = await transcription.stop()
                    return
                }
                isRecording = true
            } catch {
                guard generation == self.session else { return }
                errorMessage = error.localizedDescription
                if case VoiceAddError.micDenied = error { micDenied = true }
            }
        }
    }

    func endHold() {
        let generation = session
        Task {
            if let pending = startTask {
                // The engine can be slow to start (first-use model download);
                // never hang the UI on it.
                isProcessing = true
                let started = await awaitWithDeadline(seconds: 5) { await pending.value }
                guard generation == session else { return }
                if !started {
                    pending.cancel()
                    startTask = nil
                    isProcessing = false
                    errorMessage = "The speech engine is still warming up — try again."
                    return
                }
            }
            startTask = nil
            guard generation == session, isRecording else {
                isProcessing = false
                return
            }

            isRecording = false
            isProcessing = true
            UIImpactFeedbackGenerator(style: .light).impactOccurred()

            let finalTranscript = await transcription.stop()
            guard generation == session else { return }
            liveParse(finalTranscript, isFinal: true)

            transcript = ""
            level = 0
            isProcessing = false

            if items.isEmpty {
                errorMessage = finalTranscript.isEmpty
                    ? "Didn't catch that — hold and try again."
                    : "Couldn't find an amount in \"\(finalTranscript)\"."
            }
        }
    }

    // MARK: - Live recognition

    private func liveParse(_ text: String, isFinal: Bool = false) {
        transcript = text
        let parsed = VoiceExpenseParser.regexParse(text, categories: categoryNames)
        guard !parsed.isEmpty else { return }

        // Everything before the last segment is final; the last one is
        // final too once recording has stopped.
        let completeCount = isFinal ? parsed.count : parsed.count - 1

        while frozenCount < completeCount {
            emit(parsed[frozenCount], freeze: true)
            frozenCount += 1
            // One pulse the moment an item is fully recognized.
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        if !isFinal, parsed.count > frozenCount, let last = parsed.last {
            emit(last, freeze: false)
        }
        if isFinal { growingID = nil }
    }

    /// Routes a parsed segment into the visible list: updates the growing
    /// row in place, or appends a new row that springs out of the button.
    /// A growing row the user deleted mid-speech stays deleted.
    private func emit(_ parsed: ParsedExpense, freeze: Bool) {
        if let id = growingID {
            if let index = items.firstIndex(where: { $0.id == id }) {
                items[index].name = parsed.name
                items[index].amount = parsed.amount
                items[index].daysAgo = parsed.daysAgo
                items[index].category = parsed.category
            }
            if freeze { growingID = nil }
            return
        }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
            items.append(parsed)
        }
        growingID = freeze ? nil : parsed.id
    }

    // MARK: - Edits

    func delete(_ item: ParsedExpense) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            items.removeAll { $0.id == item.id }
        }
    }

    // MARK: - Finish

    private var validItems: [ParsedExpense] {
        items.filter {
            !$0.name.trimmingCharacters(in: .whitespaces).isEmpty && $0.amount > 0
        }
    }

    var canSave: Bool { !validItems.isEmpty }
    var saveCount: Int { validItems.count }

    func saveAll() {
        let today = Calendar.current.startOfDay(for: .now)
        for item in validItems {
            let day = Calendar.current.date(byAdding: .day, value: -item.daysAgo, to: today) ?? today
            store.add(
                Expense(
                    name: item.name.trimmingCharacters(in: .whitespaces),
                    price: item.amount,
                    billingCycle: .oneTime,
                    type: .expense,
                    startDate: day,
                    category: item.category,
                    list: "Personal"
                )
            )
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
    }

    func dismiss() {
        session += 1
        let wasRecording = isRecording
        isActive = false
        isRecording = false
        isProcessing = false
        items = []
        transcript = ""
        errorMessage = nil
        level = 0
        frozenCount = 0
        growingID = nil
        if wasRecording {
            Task { _ = await transcription.stop() }
        }
        // A still-starting session cleans itself up: its generation check
        // fails after start() returns and it stops the mic.
        startTask?.cancel()
        startTask = nil
    }
}
