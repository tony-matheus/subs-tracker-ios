import Foundation
import Observation
import SwiftUI

/// Voice quick-add: hold-to-speak model. Hold the button → live transcript;
/// release → parse → new items land at the top of the list. Speak as many
/// bursts as you like, then save all.
@Observable
@MainActor
final class VoiceAddViewModel {

    var isRecording = false
    var isProcessing = false
    var transcript: String = ""
    var items: [ParsedExpense] = []
    var errorMessage: String?
    /// Mic permission denied → the view offers a Settings deep link.
    var micDenied = false

    let date: Date
    let store: AppStore
    let settingsStore: SettingsStore

    private let transcription = SpeechTranscriptionService()
    /// Start is async (permission prompt, model download); a fast release
    /// must wait for it before stopping.
    private var startTask: Task<Void, Never>?

    init(date: Date, store: AppStore, settingsStore: SettingsStore) {
        self.date = date
        self.store = store
        self.settingsStore = settingsStore
    }

    var categoryNames: [String] {
        settingsStore.settings.categories.map(\.name)
    }

    var categories: [AppCategory] {
        settingsStore.settings.categories
    }

    /// Same resolution as everywhere an expense renders: saved override →
    /// template colors → neutral fallback (initials via `preferInitials`).
    func customization(for item: ParsedExpense) -> LogoCustomization {
        LogoCustomization.resolved(for: item.id, name: item.name, in: store)
    }

    // MARK: - Hold to speak

    func beginHold() {
        guard !isRecording, !isProcessing, startTask == nil else { return }
        errorMessage = nil
        transcript = ""
        startTask = Task {
            do {
                try await transcription.start { [weak self] text in
                    self?.transcript = text
                }
                isRecording = true
            } catch {
                errorMessage = error.localizedDescription
                if case VoiceAddError.micDenied = error { micDenied = true }
            }
        }
    }

    func endHold() {
        Task {
            await startTask?.value
            startTask = nil
            guard isRecording else { return }

            isRecording = false
            isProcessing = true
            let finalTranscript = await transcription.stop()
            transcript = ""

            guard !finalTranscript.isEmpty else {
                errorMessage = "Didn't catch that — try again."
                isProcessing = false
                return
            }

            let parsed = await VoiceExpenseParser.parse(
                transcript: finalTranscript,
                categories: categoryNames
            )
            if parsed.isEmpty {
                errorMessage = "Couldn't find an amount in \"\(finalTranscript)\" — try again."
            } else {
                // Newest utterance lands on top.
                withAnimation(.spring(duration: 0.35)) {
                    items.insert(contentsOf: parsed, at: 0)
                }
            }
            isProcessing = false
        }
    }

    /// Sheet dismissed mid-hold: tear down capture without parsing.
    func cancelRecording() async {
        startTask?.cancel()
        startTask = nil
        guard isRecording else { return }
        isRecording = false
        _ = await transcription.stop()
    }

    // MARK: - Review edits

    func addBlankItem() {
        items.append(ParsedExpense(name: "", amount: 0))
    }

    /// "Today", "Yesterday", or a short date for the review row caption.
    func dateLabel(for item: ParsedExpense) -> String {
        switch item.daysAgo {
        case 0: return "Today"
        case 1: return "Yesterday"
        default:
            return resolvedDate(for: item).formatted(.dateTime.month(.abbreviated).day())
        }
    }

    private func resolvedDate(for item: ParsedExpense) -> Date {
        let day = Calendar.current.date(byAdding: .day, value: -item.daysAgo, to: date) ?? date
        return Calendar.current.startOfDay(for: day)
    }

    // MARK: - Saving

    private var validItems: [ParsedExpense] {
        items.filter {
            !$0.name.trimmingCharacters(in: .whitespaces).isEmpty && $0.amount > 0
        }
    }

    var canSave: Bool { !validItems.isEmpty }

    var saveCount: Int { validItems.count }

    var totalPrice: Double {
        validItems.reduce(0) { $0 + $1.amount }
    }

    /// Persists every valid item as a one-time expense on its spoken date.
    func saveAll() {
        for item in validItems {
            store.add(
                Expense(
                    name: item.name.trimmingCharacters(in: .whitespaces),
                    price: item.amount,
                    billingCycle: .oneTime,
                    type: .expense,
                    startDate: resolvedDate(for: item),
                    category: item.category,
                    list: "Personal"
                )
            )
        }
    }
}
