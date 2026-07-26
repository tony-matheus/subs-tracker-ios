import SwiftUI

/// First-launch tour: five feature highlights followed by a quick multi-add
/// form. Pages swap with the liquid ripple transition (a paging TabView would
/// fight the drag-driven ripple shader, so navigation is button-driven).
struct OnboardingView: View {
    @State private var viewModel: OnboardingViewModel
    let onFinish: () -> Void

    init(
        store: AppStore,
        settingsStore: SettingsStore,
        onFinish: @escaping () -> Void
    ) {
        _viewModel = State(
            initialValue: OnboardingViewModel(
                store: store,
                settingsStore: settingsStore
            )
        )
        self.onFinish = onFinish
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                pageContent
                    .id(viewModel.page)
                    .transition(
                        .liquidRipple(
                            from: viewModel.movingForward ? .trailing : .leading
                        )
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(duration: 0.55), value: viewModel.page)

            controls
        }
        .appBackground()
    }

    @ViewBuilder
    private var pageContent: some View {
        switch viewModel.page {
        // case .welcome:
        //     OnboardingFeaturePage(
        //         title: "Meet your money crow",
        //         subtitle: "Crows hoard shiny things. This one hoards your savings — tracking every expense so nothing slips away."
        //     ) {
        //         OnboardingMascotHero()
        //     }
        case .calendar:
            OnboardingFeaturePage(
                title: "Every dollar has a date",
                subtitle: "Linguica tracks your expenses and subscriptions, each landing on its renewal day. Drag a finger across the calendar — go on, make waves."
            ) {
                OnboardingCalendarHero()
            }
        case .budget:
            OnboardingFeaturePage(
                title: "Draw the line",
                subtitle: "Pick a monthly limit and watch your spending fill the bar — green while you're cruising, red as it climbs."
            ) {
                OnboardingBudgetHero()
            }
        case .organize:
            OnboardingFeaturePage(
                title: "Sort it your way",
                subtitle: "Lists, categories, payment methods — group your spending however your brain files things. All of it customizable."
            ) {
                OnboardingOrganizeHero()
            }
        case .stats:
            OnboardingFeaturePage(
                title: "See where it all goes",
                subtitle: "Charts and forecasts turn a month of spending into one clear picture — what's gone, and what's coming."
            ) {
                OnboardingStatsHero()
            }
        // Hidden with the `.voice` page while the speech capture is improved:
        // case .voice:
        //     OnboardingFeaturePage(
        //         title: "Just say it",
        //         subtitle: "Hold the + button and rattle off expenses in one breath. Linguica listens, transcribes, and files each one for you."
        //     ) {
        //         OnboardingVoiceHero()
        //     }
        case .choosePath:
            OnboardingChoosePage(viewModel: viewModel, onFinish: onFinish)
        case .quickAdd:
            OnboardingQuickAddPage(viewModel: viewModel, onFinish: onFinish)
        }
    }

    /// Standard Skip/Next row shows only on the feature-highlight pages.
    /// `.choosePath` and `.quickAdd` navigate via their own buttons.
    private var showsStandardControls: Bool {
        viewModel.page != .quickAdd && viewModel.page != .choosePath
    }

    @ViewBuilder
    private var controls: some View {
        if showsStandardControls {
            VStack(spacing: 16) {
                pageDots

                HStack {
                    AppButton(
                        title: "Skip",
                        style: .neutral,
                        appearance: .ghost
                    ) {
                        onFinish()
                    }

                    Spacer()

                    AppButton(
                        title: "Next",
                        icon: "arrow.right",
                        style: .primary,
                        appearance: .glassy
                    ) {
                        viewModel.next()
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        } else {
            pageDots
                .padding(.bottom, 12)
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingPage.allCases, id: \.rawValue) { page in
                Capsule()
                    .fill(
                        page == viewModel.page
                            ? AnyShapeStyle(Color.appAccent.gradient)
                            : AnyShapeStyle(Color.primary.opacity(0.2))
                    )
                    .frame(width: page == viewModel.page ? 40 : 20, height: 20)
                    .onTapGesture {
                        viewModel.go(to: page)
                    }
            }
        }
        .animation(.spring(duration: 0.35), value: viewModel.page)
    }
}

#Preview {
    OnboardingView(
        store: OnboardingMockData.makeStore(),
        settingsStore: SettingsStore(),
        onFinish: {}
    )
}
