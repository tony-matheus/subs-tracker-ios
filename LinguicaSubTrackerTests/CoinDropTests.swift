import Foundation
import Testing

@testable import LinguicaSubTracker

@Suite("Coin drop physics")
struct CoinDropTests {

    private let drop = CoinDrop(height: 160)
    private let g = CoinDrop.gravity
    private let e = CoinDrop.restitution

    @Test("Free fall matches t = √(2h/g) and v = √(2gh)")
    func freeFall() {
        #expect(abs(drop.fallDuration - (2 * 160 / g).squareRoot()) < 1e-9)
        #expect(abs(drop.impactSpeed - (2 * g * 160).squareRoot()) < 1e-6)
    }

    @Test("Each bounce keeps e² of the height and e of the flight time")
    func bounceDecay() {
        #expect(abs(drop.bounceHeight(1) - 160 * e * e) < 1e-9)
        #expect(abs(drop.bounceHeight(2) - drop.bounceHeight(1) * e * e) < 1e-9)
        #expect(abs(drop.bounceRise(1) - drop.fallDuration * e) < 1e-9)
        #expect(abs(drop.bounceRise(2) - drop.bounceRise(1) * e) < 1e-9)
    }

    @Test("The entrance is claimed once per launch")
    @MainActor
    func entrancePlaysOnce() {
        _ = CoinEntrance.claim()
        // Whoever asked first got it; nobody else does for the rest of the run.
        #expect(CoinEntrance.claim() == false)
        #expect(CoinEntrance.claim() == false)
    }

    @Test("Take-off speed, apex and rise time stay consistent")
    func selfConsistency() {
        for n in 1...3 {
            let v = drop.bounceSpeed(n)
            // Apex from the take-off speed: h = v²/2g, reached after t = v/g.
            #expect(abs(drop.bounceHeight(n) - v * v / (2 * g)) < 1e-6)
            #expect(abs(drop.bounceRise(n) - v / g) < 1e-9)
        }
    }
}
