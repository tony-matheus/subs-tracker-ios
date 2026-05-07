//
//  TotalView.swift
//  LinguicaSubTracker
//
//  Created by Tony Matheus on 23/04/26.
//

import SwiftUI

struct TotalView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var settingsStore: SettingsStore

    private var monthKey: String {
        let c = Calendar.current
        let y = c.component(.year, from: store.currentMonth)
        let m = c.component(.month, from: store.currentMonth)
        return "\(y)-\(m)"
    }

    var total: Double {
        SubscriptionService.totalForMonth(
            store.subscriptions,
            month: store.currentMonth
        )
    }

    private var formattedTotal: String {
        MoneyFormatter.format(total, settings: settingsStore.settings)
    }

    private var budgetTint: Color {
        BudgetColor.color(spent: total, budget: settingsStore.settings.monthlyBudget)
    }

    private var glowOpacity: Double {
        BudgetColor.glowOpacity(spent: total, budget: settingsStore.settings.monthlyBudget)
    }

    var body: some View {
        ZStack {
            if settingsStore.settings.monthlyBudget != nil {
                RadialGradient(
                    colors: [budgetTint.opacity(glowOpacity), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 160
                )
                .animation(.easeInOut(duration: 0.6), value: glowOpacity)
                .animation(.easeInOut(duration: 0.4), value: budgetTint)
                .allowsHitTesting(false)
            }

            VStack(spacing: 8) {
                Text(store.currentMonth.formatted(.dateTime.month().year()))
                    .typography(.titleLarge)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .id(monthKey)
                    .transition(.monthRipple)
                    .animation(.spring(response: 0.42, dampingFraction: 0.82), value: monthKey)

                MoneyDisplay(
                    text: formattedTotal,
                    tint: budgetTint,
                    onTapGesture: handleTapGesture
                )
            }
        }
    }

    func handleTapGesture() {}
}

// MARK: - Month ripple transition

private struct MonthRippleModifier: ViewModifier, Animatable {
    var phase: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func body(content: Content) -> some View {
        content
            .mask {
                GeometryReader { geo in
                    let diameter = hypot(geo.size.width, geo.size.height) * 1.35
                    Circle()
                        .frame(width: diameter, height: diameter)
                        .scaleEffect(max(0.001, phase))
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
            }
            .opacity(Double(min(1, phase * 1.08 + 0.04)))
    }
}

private extension AnyTransition {
    static var monthRipple: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: MonthRippleModifier(phase: 0.001),
                identity: MonthRippleModifier(phase: 1.12)
            ),
            removal: .opacity
                .combined(with: .scale(scale: 0.94, anchor: .center))
        )
    }
}

#Preview {
    TotalView()
        .environmentObject(AppStore())
        .environmentObject(SettingsStore())
}
