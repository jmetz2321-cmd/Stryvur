import SwiftUI

struct MainTabView: View {
    var authManager: AuthManager
    @State private var viewModel = AppViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView(viewModel: viewModel) {
                hasCompletedOnboarding = true
            }
        } else {
        ZStack {
            TabView(selection: $viewModel.selectedTab) {
                DashboardView(viewModel: viewModel, authManager: authManager)
                    .tabItem {
                        Label("Dashboard", systemImage: "heart.text.square.fill")
                    }
                    .tag(0)

                MyPlanView(viewModel: viewModel)
                    .tabItem {
                        Label("My Plan", systemImage: "list.clipboard.fill")
                    }
                    .tag(1)

                GoalsView(viewModel: viewModel)
                    .tabItem {
                        Label("Goals", systemImage: "target")
                    }
                    .tag(2)
            }
            .tint(.blue)

            if viewModel.showCelebration {
                CelebrationOverlay(message: viewModel.celebrationMessage) {
                    viewModel.showCelebration = false
                }
            }
        }
        .sheet(isPresented: $viewModel.showMorningCheckIn) {
            MorningCheckInView(viewModel: viewModel)
                .interactiveDismissDisabled(false)
        }
        .onAppear {
            if !authManager.userID.isEmpty {
                viewModel.loadFromSupabase(userId: authManager.userID)
            }
        }
        }
    }
}
