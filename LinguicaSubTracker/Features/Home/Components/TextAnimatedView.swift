//
//  TextAnimated.swift
//  LinguicaSubTracker
//
//  Created by Tony Matheus on 26/04/26.
//

import SwiftUI

struct TextAnimatedView: View {
    let text: String
    var size: CGFloat = 62
    var onTapGesture: () -> Void = {}

    @State private var displayedValue: String = ""
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Text(displayedValue)
            .typography(.displayMedium.size(size))
            .monospacedDigit()
            .contentTransition(.numericText())
            .scaleEffect(scale)
            .onAppear(perform: animateEntry)
            .onChange(of: text) { oldValue, newValue in
                animateChange(to: newValue)
            }
            .onTapGesture(perform: onTapGesture)
            .animation(.valueSpring, value: displayedValue)
            .animation(.scaleSpring, value: scale)
    }

    func animateEntry() {
        displayedValue = ""

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            animateChange(to: text)
        }
    }

    func animateChange(to newValue: String) {
        bounce()

        displayedValue = newValue

        resetScale(after: 0.05)
    }

    func bounce() {
        withAnimation(.scaleBounce) {
            scale = 1.15
        }
    }

    func resetScale(after delay: Double) {
        withAnimation(.scaleReturn.delay(delay)) {
            scale = 1.0
        }
    }
}

extension Animation {
    fileprivate static let valueSpring = Animation.spring(
        duration: 0.4,
        bounce: 0.35
    )
    fileprivate static let scaleSpring = Animation.spring(
        duration: 0.3,
        bounce: 0.5
    )

    fileprivate static let scaleBounce = Animation.spring(
        duration: 0.3,
        bounce: 0.6
    )
    fileprivate static let scaleReturn = Animation.spring(
        duration: 0.4,
        bounce: 0.4
    )
}

#Preview {
    TextAnimatedView(text: "12")
}
