import Foundation

/// Deep linking routes for the app.
/// These enable any CTA, prompt, or button to navigate directly to the exact action needed.
enum AppRoute: Equatable {
    // Dashbord actions
    case dailyCheckIn
    case connectHealth
    case manualHealthStats
    case progressHub
    case healthManage

    // Plan navigation
    case todayWorkout
    case nutrition
    case sleep

    // Onboarding / Setup
    case firstRunTour
    case subscription

    // Profile / Account
    case profile

    /// Apply this route to the view model and primary navigation state.
    func apply(to viewModel: AppViewModel, subscriptionManager: SubscriptionManager) {
        switch self {
        case .dailyCheckIn:
            // Navigate to Today tab and show check-in sheet immediately
            viewModel.selectedTab = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.showMorningCheckIn = true
            }

        case .connectHealth:
            // Navigate to Today tab, request authorization, then refresh insights
            viewModel.selectedTab = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                Task {
                    viewModel.isLoadingHealthData = true
                    await viewModel.healthKit.requestAuthorization()
                    // After authorization, regenerate insights using the new data
                    viewModel.isLoadingHealthData = false
                    viewModel.adaptAllPlans()
                }
            }

        case .manualHealthStats:
            // Navigate to Today tab and show manual stats sheet
            viewModel.selectedTab = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.activeSheet = .manualStats
            }

        case .progressHub:
            // Navigate to Today tab and show progress hub sheet
            viewModel.selectedTab = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.activeSheet = .progressHub
            }

        case .healthManage:
            // Navigate to Today tab and show health management sheet
            viewModel.selectedTab = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.activeSheet = .healthManage
            }

        case .todayWorkout:
            // Navigate to Plan tab and expand today's workout
            viewModel.selectedTab = 1
            viewModel.planSegmentRoute = "workouts"
            if let todayWorkout = viewModel.todayWorkout {
                viewModel.expandWorkoutId = todayWorkout.id
            }

        case .nutrition:
            // Navigate to Plan tab nutrition section
            viewModel.selectedTab = 1
            viewModel.planSegmentRoute = "nutrition"

        case .sleep:
            // Navigate to Plan tab sleep section
            viewModel.selectedTab = 1
            viewModel.planSegmentRoute = "sleep"

        case .firstRunTour:
            // Show first run tour overlay
            viewModel.showFirstRunTour = true

        case .subscription:
            // Show paywall
            viewModel.activeSheet = .paywall

        case .profile:
            // Could navigate to profile settings in future
            break
        }
    }
}
