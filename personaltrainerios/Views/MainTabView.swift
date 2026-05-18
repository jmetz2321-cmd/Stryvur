import SwiftUI

struct MainTabView: View {
    var authManager: AuthManager
    @State private var viewModel = AppViewModel()
    @State private var subscriptionManager = SubscriptionManager()
    @State private var showSubscribedToast = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSeenFirstRunTour") private var hasSeenFirstRunTour = false
    @AppStorage("hasShownSubscribedConfirmation") private var hasShownSubscribedConfirmation = false

    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView(viewModel: viewModel, subscriptionManager: subscriptionManager) {
                hasCompletedOnboarding = true
            }
        } else {
        ZStack {
            TabView(selection: $viewModel.selectedTab) {
                DashboardView(viewModel: viewModel, authManager: authManager, subscriptionManager: subscriptionManager)
                    .tabItem {
                        Label("Today", systemImage: "sun.max.fill")
                    }
                    .tag(0)

                MyPlanView(viewModel: viewModel, subscriptionManager: subscriptionManager)
                    .tabItem {
                        Label("Plan", systemImage: "list.clipboard.fill")
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

            if viewModel.showFirstRunTour {
                FirstRunTour(isPresented: $viewModel.showFirstRunTour)
                    .zIndex(100)
            }

            if showSubscribedToast {
                VStack {
                    SubscribedConfirmationBanner()
                        .padding(.top, 60)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
                .animation(.spring(response: 0.4), value: showSubscribedToast)
                .zIndex(75)
            }

            if viewModel.showPlanUpdatedToast {
                VStack {
                    PlanUpdatedToast(message: viewModel.planUpdatedMessage)
                        .padding(.top, 60)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
                .animation(.spring(response: 0.4), value: viewModel.showPlanUpdatedToast)
                .zIndex(50)
            }

            if viewModel.showUndoToast {
                VStack {
                    Spacer()
                    UndoToast(
                        message: viewModel.undoToastMessage,
                        onUndo: { viewModel.undoLastWorkout() },
                        onDismiss: { viewModel.showUndoToast = false }
                    )
                    .padding(.bottom, 80)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .ignoresSafeArea(edges: .bottom)
                .animation(.spring(response: 0.4), value: viewModel.showUndoToast)
            }
        }
        .sheet(isPresented: $viewModel.showMorningCheckIn) {
            MorningCheckInView(viewModel: viewModel)
                .interactiveDismissDisabled(false)
        }
        .sheet(item: $viewModel.activeSheet) { sheet in
            switch sheet {
            case .manualStats:
                ManualStatsSheet(viewModel: viewModel)
            case .progressHub:
                ProgressHubSheet(viewModel: viewModel)
            case .healthManage:
                HealthManageSheet(viewModel: viewModel)
            case .help:
                HelpView(authManager: authManager)
            case .paywall:
                PaywallView(subscriptionManager: subscriptionManager)
            }
        }
        .onAppear {
            if !authManager.userID.isEmpty {
                viewModel.loadFromSupabase(userId: authManager.userID)
            }
            let isExisting = SubscriptionManager.isExistingUserOnFirstSubLaunch()
            subscriptionManager.bootstrapTrial(isExistingUser: isExisting)
            if !hasSeenFirstRunTour {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    hasSeenFirstRunTour = true
                    viewModel.showFirstRunTour = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NotificationCoordinator.didTapNotification)) { note in
            if let raw = note.object as? String,
               let route = NotificationManager.Route(rawValue: raw) {
                handleNotificationRoute(route)
            }
        }
        .task {
            // Handle any route stashed from a cold launch
            if let route = NotificationCoordinator.consumePendingRoute() {
                handleNotificationRoute(route)
            }
        }
        .onChange(of: subscriptionManager.isSubscribed) { _, nowSubscribed in
            if nowSubscribed && !hasShownSubscribedConfirmation {
                FeedbackManager.success()
                hasShownSubscribedConfirmation = true
                withAnimation { showSubscribedToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    withAnimation { showSubscribedToast = false }
                }
            } else if !nowSubscribed {
                // Allow re-confirmation if they re-subscribe later
                hasShownSubscribedConfirmation = false
            }
        }
        }
    }

    /// Routes the app to the right destination based on which notification was tapped.
    /// Uses the unified AppRoute deep linking system for consistency.
    private func handleNotificationRoute(_ route: NotificationManager.Route) {
        let appRoute: AppRoute
        switch route {
        case .checkIn:
            appRoute = .dailyCheckIn
        case .workout:
            appRoute = .todayWorkout
        case .nutrition, .hydration:
            appRoute = .nutrition
        case .streak, .weeklySummary:
            appRoute = .progressHub
        }
        appRoute.apply(to: viewModel, subscriptionManager: subscriptionManager)
    }
}
