import SwiftUI

struct EnsoMark: View {
    let date: Date
    let size: CGSize
    var isToday = false
    var animates = true
    var replay = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0

    var body: some View {
        let seed = EnsoShape.seed(for: date)
        let color: Color = isToday ? .shu : .ruleStrong.opacity(0.30)
        Group {
            if isToday && animates && !reduceMotion {
                EnsoReveal(seed: seed, size: size, color: color, progress: progress)
            } else {
                InkBrush(seed: seed, size: size, color: color)
            }
        }
        .task(id: "\(seed)-\(replay)-\(animates)-\(reduceMotion)") {
            guard isToday, animates, !reduceMotion else { progress = 1; return }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { progress = 0 }
            // Commit the reset before replay; otherwise SwiftUI can coalesce
            // the reset and final state into one update with no visible draw.
            do { try await Task.sleep(for: .milliseconds(16)) }
            catch { return }
            withAnimation(.timingCurve(0.2, 0.7, 0.3, 1, duration: 0.55)) { progress = 1 }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The same animatable mask remains mounted through the final frame. The wide
/// reveal stroke covers every cached bristle, so a complete reveal is identical
/// to the static brush used by settings and widgets.
struct EnsoReveal: View {
    let seed: UInt64
    let size: CGSize
    let color: Color
    var progress: CGFloat

    var body: some View {
        InkBrush(seed: seed, size: size, color: color)
            .mask {
                EnsoShape(seed: seed)
                    .trim(from: 0, to: progress)
                    .stroke(style: StrokeStyle(lineWidth: min(size.width, size.height) * 0.28, lineCap: .round))
            }
    }
}
