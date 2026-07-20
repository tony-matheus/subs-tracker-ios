import SwiftUI

/// Lightweight voice-capture layer over the Home screen: backdrop blur,
/// minimal expense rows growing upward from the action button, and a live
/// transcript hint. The button itself stays in `HomeView` (above this
/// overlay) so it never moves — rows appear to spring out of it.
struct VoiceCaptureOverlay: View {
    @Bindable var viewModel: VoiceCaptureViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            // Backdrop blur — Home stays visible underneath.
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    guard !viewModel.isRecording else { return }
                    viewModel.dismiss()
                }

            VStack(spacing: 12) {
                Spacer(minLength: 0)

                if viewModel.items.isEmpty && !viewModel.isRecording {
                    hint
                }

                if !viewModel.items.isEmpty {
                    itemRows
                }

                statusLine

                if !viewModel.isRecording && !viewModel.items.isEmpty {
                    actions
                }
            }
            .padding(.horizontal, 24)
            // Clear the floating button (64pt) + its breathing room.
            .padding(.bottom, 108)
        }
        // Always-visible exit while not recording — covers the zero-item and
        // error dead-ends where the actions row never appears.
        .overlay(alignment: .topTrailing) {
            if !viewModel.isRecording {
                AppButton(
                    icon: "xmark",
                    accessibilityTitle: "Close",
                    style: .neutral,
                    appearance: .glassy
                ) {
                    viewModel.dismiss()
                }
                .padding(.top, 8)
                .padding(.trailing, 20)
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: viewModel.isRecording)
    }

    // MARK: - Rows

    private var itemRows: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach($viewModel.items) { $item in
                    row($item)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.1, anchor: .bottom)
                                    .combined(with: .move(edge: .bottom))
                                    .combined(with: .opacity),
                                removal: .scale(scale: 0.85).combined(with: .opacity)
                            )
                        )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .defaultScrollAnchor(.bottom)
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxHeight: 380)
        .animation(.spring(response: 0.42, dampingFraction: 0.72), value: viewModel.items)
    }

    /// Minimal row: name + amount. No logos, no cards, no decorations.
    private func row(_ item: Binding<ParsedExpense>) -> some View {
        HStack(spacing: 10) {
            TextField("Name", text: item.name)
                .typography(.bodyLarge)
                .foregroundStyle(.primary)

            Spacer(minLength: 8)

            HStack(spacing: 2) {
                Text(viewModel.currencySymbol)
                    .foregroundStyle(.secondary)
                TextField(
                    "0.00",
                    value: item.amount,
                    format: .number.precision(.fractionLength(2))
                )
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .fixedSize()
            }
            .typography(.titleSmall)

            Button {
                viewModel.delete(item.wrappedValue)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.appSurface.opacity(0.85), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Status & actions

    private var hint: some View {
        VStack(spacing: 6) {
            Text("Hold the button and speak")
                .typography(.titleMedium)
                .foregroundStyle(.primary)
            Text("\"50 dollars on Safeway, 20 at Starbucks…\"")
                .typography(.bodyMedium)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var statusLine: some View {
        if viewModel.isRecording && !viewModel.transcript.isEmpty {
            Text(viewModel.transcript)
                .typography(.bodyMedium)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .contentTransition(.interpolate)
        } else if let message = viewModel.errorMessage {
            VStack(spacing: 6) {
                Text(message)
                    .typography(.bodySmall)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                if viewModel.micDenied {
                    Button("Open Settings") {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    }
                    .typography(.labelLarge)
                }
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 12) {
            AppButton(
                icon: "xmark",
                accessibilityTitle: "Discard",
                style: .neutral,
                appearance: .glassy
            ) {
                viewModel.dismiss()
            }

            AppButton(
                title: "Add \(viewModel.saveCount) expense\(viewModel.saveCount == 1 ? "" : "s")",
                icon: "checkmark",
                style: .primary,
                appearance: .solid,
                size: .large,
                expands: true,
                isDisabled: !viewModel.canSave
            ) {
                viewModel.saveAll()
            }
        }
    }
}

/// Scrolling voice waveform (Voice Memos style): bars sample the mic level
/// and march left as new audio arrives, newest bar at the right edge.
struct WaveformLine: View {
    /// Target level 0…1 from the view model.
    var level: Float
    var barWidth: CGFloat = 3
    var barSpacing: CGFloat = 3

    @State private var history = History()

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { canvas, size in
                history.step(
                    target: Double(level),
                    time: context.date.timeIntervalSinceReferenceDate
                )

                let slot = barWidth + barSpacing
                let capacity = max(1, Int(size.width / slot))
                let bars = history.samples.suffix(capacity)
                let midY = size.height / 2

                for (offset, magnitude) in bars.enumerated() {
                    let x = size.width - CGFloat(bars.count - offset) * slot
                    let height = max(3, magnitude * size.height)
                    let rect = CGRect(
                        x: x,
                        y: midY - height / 2,
                        width: barWidth,
                        height: height
                    )
                    canvas.fill(
                        Path(roundedRect: rect, cornerRadius: barWidth / 2),
                        with: .color(.purple.opacity(0.35 + magnitude * 0.65))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// Eased level sampled at a fixed rate so the strip scrolls steadily
    /// regardless of display refresh rate.
    final class History {
        var samples: [Double] = []
        private var eased: Double = 0
        private var lastSampleTime: TimeInterval = 0

        func step(target: Double, time: TimeInterval) {
            eased += (target - eased) * 0.3
            guard time - lastSampleTime >= 0.05 else { return }
            lastSampleTime = time
            samples.append(eased)
            if samples.count > 400 {
                samples.removeFirst(samples.count - 400)
            }
        }
    }
}
