import Foundation
import Observation

@Observable
@MainActor
final class ColorPresetPickerViewModel {
    let presets: [String] = [
        "#FF3B30", "#FF6B00", "#FF9500", "#FFD60A",
        "#34C759", "#00C7BE", "#007AFF", "#5856D6",
        "#AF52DE", "#FF2D55", "#8E8E93", "#000000",
    ]

    func isSelected(_ hex: String, current: String) -> Bool {
        hex == current
    }
}
