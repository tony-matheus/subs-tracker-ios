import SwiftUI

/// Shared, deterministic centerline. Callers can stroke/trim this shape at any size.
struct EnsoShape: Shape {
    var seed: UInt64

    static func seed(for date: Date, calendar: Calendar = .current) -> UInt64 {
        let parts = calendar.dateComponents([.era, .year, .month, .day], from: date)
        let day = UInt64(max(0, (parts.era ?? 1) * 10_000_000 + (parts.year ?? 0) * 10_000
            + (parts.month ?? 1) * 100 + (parts.day ?? 1)))
        return mixed(day)
    }

    static func mixed(_ input: UInt64) -> UInt64 {
        var x = input &+ 0x9e3779b97f4a7c15
        x = (x ^ (x >> 30)) &* 0xbf58476d1ce4e5b9
        x = (x ^ (x >> 27)) &* 0x94d049bb133111eb
        return x ^ (x >> 31)
    }

    func variation(_ index: UInt64) -> Double {
        Double(Self.mixed(seed &+ index) % 10_000) / 10_000
    }

    func point(at t: Double, in rect: CGRect) -> CGPoint {
        let angle = variation(1) * .pi * 2 + t * (.pi * (1.65 + variation(2) * 0.23))
        let drift = 1 + 0.055 * sin(angle * 3 + variation(3) * 6)
            + 0.035 * sin(angle * 5 + variation(4) * 6)
        return CGPoint(x: rect.midX + cos(angle) * rect.width * 0.35 * drift,
                       y: rect.midY + sin(angle) * rect.height * 0.34 * drift)
    }

    func path(in rect: CGRect) -> Path {
        Path { path in
            for i in 0...160 {
                let point = point(at: Double(i) / 160, in: rect)
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
        }
    }
}
