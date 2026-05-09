import SwiftUI
import UIKit

struct DialItem: Identifiable, Equatable {
    let id: String
    let label: String
    let amount: Double
    let color: Color
}

struct SpendDial: View {
    let items: [DialItem]
    @Binding var selectedID: String?

    let totalLabel: String        // formatted money for selected slice
    let percentLabel: String      // e.g. "69%"
    let velocityBoost: Double = 1.3

    @State private var rotation: Double = 0           // degrees, clockwise positive
    @State private var previousAngle: Double? = nil
    @State private var lastSampleTime: Date? = nil
    @State private var velocity: Double = 0           // deg/sec
    @State private var decayTimer: Timer? = nil

    private let ringWidth: CGFloat = 16
    private let gapPoints: CGFloat = 24

    private var total: Double { items.reduce(0) { $0 + $1.amount } }

    private var fractions: [Double] {
        guard total > 0 else { return [] }
        return items.map { $0.amount / total }
    }

    private var cumulative: [Double] {
        var acc: Double = 0
        var out: [Double] = []
        for f in fractions {
            out.append(acc)
            acc += f
        }
        return out
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let ringRadius = (size - ringWidth - 24) / 2  // padding 12 + ringWidth/2 inset on each side
            let gapDegrees: Double = ringRadius > 0 ? Double(gapPoints) / Double(ringRadius) * 180 / .pi : 0
            let gapFraction = gapDegrees / 360
            let glowColor = selectedItem?.color ?? .gray

            ZStack {
                // Soft colored glow behind dial
                RadialGradient(
                    colors: [glowColor.opacity(0.35), glowColor.opacity(0.0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
                .blur(radius: 30)
                .animation(.easeInOut(duration: 0.4), value: glowColor)

                // Outer glass disc — sits behind the ring; segments render on top, unblurred.
                Circle()
                    .glassEffect(.regular, in: Circle())

                // Segments group (rotates with dial), in front of glass
                ZStack {
                    ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                        let frac = fractions[idx]
                        let start = cumulative[idx]
                        let half = gapFraction / 2
                        let trimStart = start + half
                        let trimEnd = start + frac - half
                        if trimEnd > trimStart {
                            Circle()
                                .trim(from: trimStart, to: trimEnd)
                                .stroke(
                                    item.color,
                                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                                )
                                .padding(ringWidth / 2 + 12)
                        }
                    }
                }
                .rotationEffect(.degrees(-90 + rotation))
                .contentShape(RingHitShape(ringWidth: ringWidth + 16))
                .gesture(dragGesture(size: size))

                // Top indicator (outside glass + ring)
                Triangle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 12, height: 8)
                    .offset(y: -(size / 2 + 8))

                // Center label
                centerLabel
                    .padding(ringWidth + 36)
                    .allowsHitTesting(false)
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: items) { _, _ in
            stopDecay()
            rotation = 0
            previousAngle = nil
            velocity = 0
            updateSelection(initial: true)
        }
        .onAppear {
            updateSelection(initial: true)
        }
        .onDisappear {
            stopDecay()
        }
    }

    @ViewBuilder
    private var centerLabel: some View {
        if let id = selectedID, let item = items.first(where: { $0.id == id }) {
            VStack(spacing: 6) {
                Text(item.label)
                    .typography(.headlineMedium)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 6) {
                    Text(totalLabel)
                    Text("•")
                    Text(percentLabel)
                }
                .typography(.bodyMedium)
                .foregroundStyle(.secondary)
            }
        } else {
            Text("No data")
                .typography(.titleMedium)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Gesture

    private func dragGesture(size: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                stopDecay()
                handleDragChanged(value, size: size)
            }
            .onEnded { _ in
                previousAngle = nil
                lastSampleTime = nil
                startDecayIfNeeded()
            }
    }

    private func handleDragChanged(_ value: DragGesture.Value, size: CGFloat) {
        let center = CGPoint(x: size / 2, y: size / 2)
        let dx = value.location.x - center.x
        let dy = value.location.y - center.y
        guard dx != 0 || dy != 0 else { return }
        let angle = atan2(dy, dx) * 180 / .pi
        let now = Date()
        if let prev = previousAngle {
            var delta = angle - prev
            if delta > 180 { delta -= 360 }
            if delta < -180 { delta += 360 }
            rotation += delta
            if let lt = lastSampleTime {
                let dt = max(0.0001, now.timeIntervalSince(lt))
                velocity = delta / dt * velocityBoost
            }
            updateSelection(initial: false)
        }
        previousAngle = angle
        lastSampleTime = now
    }

    // MARK: - Physics decay

    private func startDecayIfNeeded() {
        guard abs(velocity) > 220 else { velocity = 0; return }  // below threshold → just stop
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { t in
            // Apply
            rotation += velocity * (1.0 / 60.0)
            velocity *= 0.975
            updateSelection(initial: false)
            if abs(velocity) < 2 {
                t.invalidate()
                decayTimer = nil
                velocity = 0
            }
        }
        decayTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopDecay() {
        decayTimer?.invalidate()
        decayTimer = nil
    }

    // MARK: - Selection

    private var topFraction: Double {
        let t = (-rotation / 360.0).truncatingRemainder(dividingBy: 1)
        return t < 0 ? t + 1 : t
    }

    /// Returns the segment whose drawn arc currently spans the top indicator,
    /// accounting for the gap. Returns nil if the indicator is over a gap.
    private func segmentIndexAtTop() -> Int? {
        guard !items.isEmpty, total > 0 else { return nil }
        // Match the drawing's gap: half-gap on each side of every segment.
        // We need a radius-aware gapFraction; recompute using the canonical layout (uses radius from geometry).
        // Since we don't have geometry here, we approximate using the smaller-side estimate.
        // Selection still works: if t is inside [trimStart, trimEnd] of any segment, that's the hit.
        let t = topFraction
        // Use a small fixed gap fraction (~ same magnitude as drawing). Conservative — if topFraction
        // lands precisely in the gap we return nil (caller preserves prior selection).
        let approxGapFraction = 0.012  // ~4.3°; visual gap is similar; conservative for hit-testing
        for (i, start) in cumulative.enumerated() {
            let half = approxGapFraction / 2
            let trimStart = start + half
            let trimEnd = start + fractions[i] - half
            if t >= trimStart && t < trimEnd { return i }
        }
        return nil
    }

    private var selectedItem: DialItem? {
        guard let id = selectedID else { return nil }
        return items.first { $0.id == id }
    }

    private func updateSelection(initial: Bool) {
        guard let idx = segmentIndexAtTop() else {
            // In a gap — keep previous selection (unless none was set yet).
            if initial, selectedID == nil, let first = items.first {
                selectedID = first.id
            }
            return
        }
        let newID = items[idx].id
        if newID != selectedID {
            selectedID = newID
            if !initial {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
        }
    }
}

/// Annulus hit area — only the ring band reacts to gestures.
private struct RingHitShape: Shape {
    let ringWidth: CGFloat
    func path(in rect: CGRect) -> Path {
        let outerR = min(rect.width, rect.height) / 2
        let innerR = max(0, outerR - ringWidth)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var p = Path()
        p.addEllipse(in: CGRect(x: center.x - outerR, y: center.y - outerR, width: outerR * 2, height: outerR * 2))
        p.addEllipse(in: CGRect(x: center.x - innerR, y: center.y - innerR, width: innerR * 2, height: innerR * 2))
        return p.normalized(eoFill: true)
    }
}

#Preview {
    @Previewable @State var selected: String? = "Entertainment"
    SpendDial(
        items: [
            DialItem(id: "Entertainment", label: "Entertainment", amount: 930, color: Color(hex: "#FF3B30")),
            DialItem(id: "Productivity", label: "Productivity", amount: 250, color: Color(hex: "#34C759")),
            DialItem(id: "Lifestyle", label: "Lifestyle", amount: 166, color: Color(hex: "#FFD60A")),
        ],
        selectedID: $selected,
        totalLabel: "$930.00",
        percentLabel: "69%"
    )
    .frame(width: 320, height: 320)
    .padding()
    .background(.black)
}
