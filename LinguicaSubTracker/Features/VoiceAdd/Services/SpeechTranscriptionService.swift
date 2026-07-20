import AVFoundation
import Foundation
import Speech

enum VoiceAddError: LocalizedError {
    case micDenied
    case localeUnsupported
    case audioFormatUnavailable

    var errorDescription: String? {
        switch self {
        case .micDenied:
            return "Microphone access is off. Enable it in Settings to speak expenses."
        case .localeUnsupported:
            return "On-device transcription isn't available for your language yet."
        case .audioFormatUnavailable:
            return "Couldn't start audio capture. Try again."
        }
    }
}

/// On-device live transcription: `AVAudioEngine` mic input → `SpeechAnalyzer`
/// + `SpeechTranscriber` (iOS 26). Reports the running transcript
/// (finalized + volatile) via a callback; `stop()` returns the final text.
@MainActor
final class SpeechTranscriptionService {
    private let audioEngine = AVAudioEngine()
    private var analyzer: SpeechAnalyzer?
    private var transcriber: SpeechTranscriber?
    private var inputBuilder: AsyncStream<AnalyzerInput>.Continuation?
    private var resultsTask: Task<Void, Never>?

    private var finalized: String = ""
    private var volatile: String = ""

    var transcript: String {
        (finalized + volatile).trimmingCharacters(in: .whitespaces)
    }

    func start(
        onUpdate: @escaping @MainActor (String) -> Void,
        onLevel: (@MainActor (Float) -> Void)? = nil
    ) async throws {
        guard await AVAudioApplication.requestRecordPermission() else {
            throw VoiceAddError.micDenied
        }

        // Locale + model. Downloads the on-device model on first use.
        let supported = await SpeechTranscriber.supportedLocales
        guard let locale = supported.first(where: {
            $0.identifier(.bcp47) == Locale.current.identifier(.bcp47)
        }) ?? supported.first(where: {
            $0.language.languageCode == Locale.current.language.languageCode
        }) else {
            throw VoiceAddError.localeUnsupported
        }

        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: []
        )
        self.transcriber = transcriber

        if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try await request.downloadAndInstall()
        }

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        self.analyzer = analyzer

        guard let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [transcriber]
        ) else {
            throw VoiceAddError.audioFormatUnavailable
        }

        finalized = ""
        volatile = ""

        // Consume results as they stream in.
        resultsTask = Task { [weak self] in
            do {
                for try await result in transcriber.results {
                    guard let self else { return }
                    let text = String(result.text.characters)
                    if result.isFinal {
                        self.finalized += text
                        self.volatile = ""
                    } else {
                        self.volatile = text
                    }
                    onUpdate(self.transcript)
                }
            } catch {
                // Stream ends on stop/finalize; nothing to surface here.
            }
        }

        let (inputSequence, inputBuilder) = AsyncStream<AnalyzerInput>.makeStream()
        self.inputBuilder = inputBuilder
        try await analyzer.start(inputSequence: inputSequence)

        // Mic capture.
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let inputFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        let converter = BufferConverter(from: inputFormat, to: analyzerFormat)
        audioEngine.inputNode.installTap(
            onBus: 0,
            bufferSize: 2048,
            format: inputFormat
        ) { buffer, _ in
            if let onLevel {
                let level = Self.rmsLevel(of: buffer)
                Task { @MainActor in onLevel(level) }
            }
            guard let converted = converter?.convert(buffer) else { return }
            inputBuilder.yield(AnalyzerInput(buffer: converted))
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    /// Stops capture, finalizes pending audio, and returns the full transcript.
    /// Finalization is capped at a few seconds — `finalizeAndFinishThroughEndOfInput`
    /// can hang indefinitely (notably on the simulator); we then fall back to
    /// the transcript already received.
    func stop() async -> String {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        inputBuilder?.finish()
        inputBuilder = nil

        let analyzer = self.analyzer
        let results = self.resultsTask
        _ = await awaitWithDeadline(seconds: 3) {
            try? await analyzer?.finalizeAndFinishThroughEndOfInput()
            await results?.value
        }
        resultsTask?.cancel()
        resultsTask = nil
        self.analyzer = nil
        transcriber = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return transcript
    }

    /// RMS of the buffer's first channel — drives the recording waveform.
    /// Runs on the audio thread.
    private nonisolated static func rmsLevel(of buffer: AVAudioPCMBuffer) -> Float {
        guard let data = buffer.floatChannelData?[0] else { return 0 }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return 0 }
        var sum: Float = 0
        for i in 0..<count { sum += data[i] * data[i] }
        return sqrt(sum / Float(count))
    }
}

/// Awaits `op`, returning `true` if it finished within `seconds`, `false` on
/// deadline (op keeps running detached). For OS speech APIs that can hang and
/// ignore cancellation — the caller must never be blocked forever.
@MainActor
func awaitWithDeadline(
    seconds: Double,
    _ op: @escaping @MainActor () async -> Void
) async -> Bool {
    final class Once { var fired = false }
    let once = Once()
    return await withCheckedContinuation { continuation in
        Task { @MainActor in
            await op()
            guard !once.fired else { return }
            once.fired = true
            continuation.resume(returning: true)
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            guard !once.fired else { return }
            once.fired = true
            continuation.resume(returning: false)
        }
    }
}

/// Converts mic buffers to the analyzer's preferred format. Lives off the
/// main actor because the tap block runs on the audio thread.
private nonisolated final class BufferConverter: @unchecked Sendable {
    private let converter: AVAudioConverter
    private let outputFormat: AVAudioFormat

    init?(from input: AVAudioFormat, to output: AVAudioFormat) {
        guard let c = AVAudioConverter(from: input, to: output) else { return nil }
        c.primeMethod = .none
        self.converter = c
        self.outputFormat = output
    }

    func convert(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        let ratio = outputFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount((Double(buffer.frameLength) * ratio).rounded(.up))
        guard let output = AVAudioPCMBuffer(
            pcmFormat: outputFormat,
            frameCapacity: max(capacity, 1)
        ) else { return nil }

        var consumed = false
        var conversionError: NSError?
        let status = converter.convert(to: output, error: &conversionError) { _, inputStatus in
            defer { consumed = true }
            inputStatus.pointee = consumed ? .noDataNow : .haveData
            return consumed ? nil : buffer
        }
        guard status != .error, conversionError == nil else { return nil }
        return output
    }
}
