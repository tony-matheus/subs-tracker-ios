import SwiftUI

enum BudgetColor {

    /// Returns the tint color for the total amount based on how close it is to the budget.
    /// - Returns: `.primary` when no budget is set.
    static func color(spent: Double, budget: Double?) -> Color {
        guard let budget, budget > 0 else { return .primary }
        let ratio = spent / budget
        switch ratio {
        case ..<0.5:   return .primary
        case 0.5..<0.75: return .yellow
        case 0.75..<0.9: return .orange
        case 0.9..<1.0:  return Color(red: 1, green: 0.35, blue: 0)
        default:          return .red
        }
    }

    /// Opacity for the background glow (0 when no budget, scales with ratio).
    static func glowOpacity(spent: Double, budget: Double?) -> Double {
        guard let budget, budget > 0 else { return 0 }
        let ratio = min(spent / budget, 1.5)
        return ratio < 0.5 ? 0 : min((ratio - 0.5) * 0.4, 0.35)
    }
}
