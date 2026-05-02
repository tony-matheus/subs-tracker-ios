import Foundation
import SwiftUI

enum DayStatus {
    case current
    case normal
    case none
}

struct DayCell: View {
    let date: Date?
    var status: DayStatus = .normal
    var height: CGFloat = 68
    var subscriptionCount: Int = 0
    var onTap: (Date) -> Void

    @State private var isPressed = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {

            // Background
            RoundedRectangle(cornerRadius: 20)
                .fill(backgroundColor)
                .overlay(borderOverlay)

            // Day number
            if displayDay, let date {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 12))
                    .padding(12)
                    .opacity(0.6)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            // 🔴 Subscription badge
            if subscriptionCount > 0 {
                badge
            }
        }
        .frame(height: height)
        .scaleEffect(isPressed ? 0.9 : 1)
        .animation(.spring(duration: 0.2, bounce: 0.4), value: isPressed)
        .onTapGesture {
            guard let date else { return }
            onTap(date)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .disabled(status == .none)
    }

    // MARK: - Badge

    private var badge: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)

            Text("\(subscriptionCount)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.black)
        }
        .padding(6)
    }

    // MARK: - Border

    @ViewBuilder
    private var borderOverlay: some View {
        switch status {
        case .current:
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                        .blur(radius: 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.7),
                                            Color.white.opacity(0.1),
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
        default:
            EmptyView()
        }
    }

    // MARK: - Helpers

    private var displayDay: Bool {
        status != .none
    }

    private var backgroundColor: Color {
        switch status {
        case .current, .normal:
            return Color.gray.opacity(0.2)
        case .none:
            return Color.gray.opacity(0.1)
        }
    }
}
struct DayClickStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(
                .spring(duration: 0.2, bounce: 0.4),
                value: configuration.isPressed
            )
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }

            }
    }
}

#Preview {
    DayCell(date: Date(), onTap: { _ in })
}
