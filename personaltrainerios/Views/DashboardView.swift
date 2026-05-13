import SwiftUI

struct DashboardView: View {
    var viewModel: AppViewModel
    var authManager: AuthManager
    var subscriptionManager: SubscriptionManager
    @State private var showSignOutConfirm = false
    @State private var showProfileMenu = false
    @State private var workoutJustCompleted = false
    @State private var coachNotesExpanded = false
    @State private var trendsExpanded = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // PRIMARY: Always shown — greeting + primary goal
                    heroCard

                    // PRIMARY: Today's workout / completed / rest day / recovery day
                    if let workout = viewModel.todayWorkout {
                        // Scheduled workout, not yet completed
                        todayWorkoutCard(workout)
                    } else if viewModel.isTodayWorkoutCompleted, let done = viewModel.todayScheduledWorkout {
                        // Workout was scheduled AND completed today
                        workoutCompletedCard(done)
                    } else if viewModel.isTodayRestDay {
                        // No workout scheduled — true rest day
                        restDayCard
                    }

                    // VALUE LAYER: Coach's Notes (AI insights — above raw data)
                    if viewModel.shouldShowCoachNotesSection {
                        insightsPreview
                    }

                    // DATA LAYER: Health metrics (supporting data)
                    healthSection

                    // SECONDARY: Getting started (day 1-2 only, hidden after setup)
                    if viewModel.shouldShowGettingStartedCard {
                        gettingStartedCard
                    }

                    // SECONDARY: Progress hub (day 3+)
                    if viewModel.shouldShowProgressHub {
                        progressHubCard
                    }

                    // TERTIARY: Trends (only after 3+ check-ins)
                    if viewModel.shouldShowTrendsSection {
                        checkInTrends
                    }

                    // TERTIARY: Subscription reminders (day 4+ only)
                    if subscriptionManager.hasExpiredTrial {
                        trialExpiredCard
                    } else if viewModel.shouldShowTrialReminderCard && showTrialReminderCard {
                        trialReminderCard
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showProfileMenu = true
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                    .accessibilityLabel("Profile menu")
                }
            }
            .confirmationDialog("Account", isPresented: $showProfileMenu, titleVisibility: .visible) {
                if subscriptionManager.isSubscribed {
                    Button("Manage Subscription") {
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    }
                } else {
                    Button("Subscribe to Premium") {
                        AppRoute.subscription.apply(to: viewModel, subscriptionManager: subscriptionManager)
                    }
                }
                if !viewModel.healthKit.isAuthorized {
                    Button("Connect Apple Health") {
                        AppRoute.connectHealth.apply(to: viewModel, subscriptionManager: subscriptionManager)
                    }
                }
                Button("Edit Health Stats") {
                    AppRoute.manualHealthStats.apply(to: viewModel, subscriptionManager: subscriptionManager)
                }
                Button("Help & FAQ") {
                    viewModel.activeSheet = .help
                }
                Button("Replay Tour") {
                    AppRoute.firstRunTour.apply(to: viewModel, subscriptionManager: subscriptionManager)
                }
                Button("Sign Out", role: .destructive) {
                    showSignOutConfirm = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if !authManager.userName.isEmpty {
                    Text(authManager.userName)
                }
            }
            .confirmationDialog("Sign Out?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You can sign back in anytime with Apple.")
            }
            .task {
                if viewModel.healthKit.isAuthorized {
                    viewModel.isLoadingHealthData = true
                    await viewModel.healthKit.fetchTodayData()
                    viewModel.isLoadingHealthData = false
                }
                viewModel.adaptAllPlans()
            }
            .refreshable {
                viewModel.isLoadingHealthData = true
                await viewModel.healthKit.fetchTodayData()
                viewModel.isLoadingHealthData = false
                viewModel.adaptAllPlans()
            }
            .onChange(of: viewModel.healthKit.isAuthorized) { _, newValue in
                // When health authorization changes (e.g. after Settings approval),
                // refresh data and regenerate Coach's Notes
                if newValue {
                    Task {
                        viewModel.isLoadingHealthData = true
                        await viewModel.healthKit.fetchTodayData()
                        viewModel.isLoadingHealthData = false
                        viewModel.adaptAllPlans()
                    }
                }
            }
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(coachGreeting)
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            if let primary = viewModel.goals.first(where: { !$0.isCompleted }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color(primary.category.color).opacity(0.15), lineWidth: 5)
                        Circle()
                            .trim(from: 0, to: primary.progress)
                            .stroke(Color(primary.category.color), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.spring, value: primary.progress)
                        Text("\(Int(primary.progress * 100))%")
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(primary.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(CoachCopy.goalEncouragement(progress: primary.progress, title: primary.title))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                let otherGoals = viewModel.goals.filter { !$0.isCompleted && $0.id != primary.id }
                if !otherGoals.isEmpty {
                    ForEach(otherGoals) { goal in
                        HStack(spacing: 10) {
                            Image(systemName: goal.category.icon)
                                .font(.caption)
                                .foregroundStyle(Color(goal.category.color))
                                .frame(width: 20)
                            Text(goal.title)
                                .font(.caption)
                            Spacer()
                            Text("\(Int(goal.progress * 100))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color(goal.category.color))
                        }
                    }
                }
            } else if viewModel.goals.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "target")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    Text(CoachCopy.noGoalsYet())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                    Text(CoachCopy.allGoalsCompleted())
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Trial Cards

    private enum TrialCardKind {
        case mid       // 4-5 days remaining — soft, value-focused
        case ending    // 1-3 days remaining — urgent
        case none
    }

    private var trialCardKind: TrialCardKind {
        guard !subscriptionManager.isSubscribed else { return .none }
        let days = subscriptionManager.daysRemainingInTrial
        if days >= 4 && days <= 5 { return .mid }
        if days > 0 && days <= 3 { return .ending }
        return .none
    }

    private var showTrialReminderCard: Bool {
        trialCardKind != .none
    }

    @ViewBuilder
    private var trialReminderCard: some View {
        switch trialCardKind {
        case .mid:
            midTrialCard
        case .ending:
            endingTrialCard
        case .none:
            EmptyView()
        }
    }

    private var midTrialCard: some View {
        let days = subscriptionManager.daysRemainingInTrial
        let workouts = viewModel.workoutHistory.count
        let checkIns = viewModel.checkInHistory.count

        return Button {
            FeedbackManager.light()
            AppRoute.subscription.apply(to: viewModel, subscriptionManager: subscriptionManager)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.blue)
                        .font(.title3)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You're building real momentum")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("\(days) days of premium left")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                if workouts > 0 || checkIns > 0 {
                    HStack(spacing: 14) {
                        if workouts > 0 {
                            trialStatChip(value: "\(workouts)", label: workouts == 1 ? "workout" : "workouts")
                        }
                        if checkIns > 0 {
                            trialStatChip(value: "\(checkIns)", label: checkIns == 1 ? "check-in" : "check-ins")
                        }
                        Spacer()
                    }
                }

                HStack {
                    Text("See premium features")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .accessibilityHidden(true)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.blue.opacity(0.30), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("You're building momentum. \(days) days of premium left. Tap to see plans.")
    }

    private var endingTrialCard: some View {
        let days = subscriptionManager.daysRemainingInTrial
        return Button {
            FeedbackManager.light()
            AppRoute.subscription.apply(to: viewModel, subscriptionManager: subscriptionManager)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: days == 1 ? "clock.fill" : "clock")
                    .foregroundStyle(.orange)
                    .font(.title3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(days == 1 ? "Last day of your trial" : "\(days) days left in trial")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("Pick a plan to keep your data and Coach's Notes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding()
            .background(Color.orange.opacity(0.18), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.orange.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(days) days left in your trial. Tap to see plans.")
    }

    private func trialStatChip(value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.blue)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.regularMaterial, in: Capsule())
    }

    private var trialExpiredCard: some View {
        Button {
            FeedbackManager.warning()
            AppRoute.subscription.apply(to: viewModel, subscriptionManager: subscriptionManager)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.purple)
                    .font(.title3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your trial has ended")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Keep your Coach's Notes, history, and adaptive plans.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("See plans")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.purple, in: Capsule())
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.purple.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Trial ended. Tap to see plans.")
    }

    // MARK: - Getting Started Card (first-run + empty states)

    private var showGettingStartedCard: Bool {
        let hasCheckedIn = viewModel.todayCheckIn != nil
        let hasHealth = viewModel.healthKit.isAuthorized || viewModel.manualStats.hasData
        return !hasCheckedIn || !hasHealth
    }

    private var gettingStartedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true)
                Text("One quick setup step")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            Text("Connect Apple Health to give Coach's AI better signals.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !viewModel.healthKit.isAuthorized && !viewModel.manualStats.hasData {
                gettingStartedRow(
                    icon: "heart.fill",
                    iconColor: .red,
                    title: "Connect Apple Health",
                    subtitle: "Sync steps, sleep, and heart rate",
                    action: {
                        FeedbackManager.light()
                        AppRoute.connectHealth.apply(to: viewModel, subscriptionManager: subscriptionManager)
                    }
                )
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.15), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Setup step: Connect Apple Health")
    }

    private func gettingStartedRow(icon: String, iconColor: Color, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private var coachGreeting: String {
        let workoutsCompleted = viewModel.trainingPlan?.workouts.filter(\.isCompleted).count ?? 0
        let totalWorkouts = viewModel.trainingPlan?.workouts.count ?? 0
        return CoachCopy.greeting(
            name: authManager.userName,
            streak: viewModel.streakData.currentStreak,
            workoutsCompleted: workoutsCompleted,
            totalWorkouts: totalWorkouts,
            hasCheckedIn: viewModel.todayCheckIn != nil
        )
    }

    // MARK: - Consolidated Progress Hub

    private var progressHubCard: some View {
        Button {
            FeedbackManager.light()
            AppRoute.progressHub.apply(to: viewModel, subscriptionManager: subscriptionManager)
        } label: {
            progressHubLabel
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Your progress. Level \(viewModel.rewardProgress.level), \(viewModel.rewardProgress.totalPoints) points, \(viewModel.streakData.currentStreak) day streak.")
        .accessibilityHint("Opens full progress details")
    }

    private var progressHubLabel: some View {
        Group {
            HStack(spacing: 14) {
                // Level ring
                ZStack {
                    Circle()
                        .stroke(Color.yellow.opacity(0.2), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: viewModel.rewardProgress.levelProgress)
                        .stroke(Color.yellow, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("L\(viewModel.rewardProgress.level)")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 3) {
                    Text(CoachCopy.streakMessage(streak: viewModel.streakData.currentStreak))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("\(viewModel.rewardProgress.totalPoints) pts \u{2022} \(viewModel.rewardProgress.pointsToNextLevel) to next level")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if viewModel.streakData.currentStreak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(viewModel.streakData.currentStreak)")
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)
                }

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .background(
                LinearGradient(
                    colors: [Color.yellow.opacity(0.18), Color.orange.opacity(0.12)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.yellow.opacity(0.30), lineWidth: 1)
            )
        }
    }

    // MARK: - Today's Workout

    private func todayWorkoutCard(_ workout: Workout) -> some View {
        let isRecovery = viewModel.isTodayRecoveryDay
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: isRecovery ? "leaf.fill" : "figure.run")
                    .foregroundStyle(isRecovery ? .green : .blue)
                    .accessibilityHidden(true)
                Text(isRecovery ? "Recovery Day" : "Today's Workout")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: intensityIcon(workout.intensity))
                        .font(.caption2)
                        .accessibilityHidden(true)
                    Text(workout.intensity.rawValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(workout.intensity.color).opacity(0.2), in: Capsule())
                .foregroundStyle(Color(workout.intensity.color))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(workout.intensity.rawValue) intensity")
            }

            if viewModel.todayCheckIn == nil {
                Button {
                    FeedbackManager.light()
                    AppRoute.dailyCheckIn.apply(to: viewModel, subscriptionManager: subscriptionManager)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "sun.max.fill")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Check in to fine-tune your workout")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            Text("30 seconds — adjusts intensity to how you feel")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Check in to fine-tune your workout")
                .accessibilityHint("Takes 30 seconds. Opens daily check-in form.")
            }

            Button {
                FeedbackManager.light()
                AppRoute.todayWorkout.apply(to: viewModel, subscriptionManager: subscriptionManager)
            } label: {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        HStack(spacing: 12) {
                            Label("\(workout.durationMinutes) min", systemImage: "clock")
                            Label("\(workout.exercises.count) exercises", systemImage: "list.bullet")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            Button {
                viewModel.completeWorkout(workout.id)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    workoutJustCompleted = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    workoutJustCompleted = false
                }
            } label: {
                Text("Mark Complete")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.regular)
            .scaleEffect(workoutJustCompleted ? 1.03 : 1.0)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Rest Day Card (no workout scheduled today)

    private var restDayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
                Text("Rest Day")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            Text("Recovery is when growth happens. No workout scheduled today.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.todayCheckIn == nil {
                Button {
                    FeedbackManager.light()
                    AppRoute.dailyCheckIn.apply(to: viewModel, subscriptionManager: subscriptionManager)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "sun.max.fill")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Check in to log how you feel")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            Text("30 seconds — keeps your streak alive")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Check in to log how you feel")
                .accessibilityHint("Takes 30 seconds. Opens daily check-in form.")
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                        .accessibilityHidden(true)
                    Text("Checked in for today")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Workout Completed Card (scheduled workout was done today)

    private func workoutCompletedCard(_ workout: Workout) -> some View {
        let isRecovery = viewModel.isTodayRecoveryDay
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
                Text(isRecovery ? "Recovery Day · Done" : "Workout Complete")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(workout.intensity.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(workout.intensity.color).opacity(0.2), in: Capsule())
                    .foregroundStyle(Color(workout.intensity.color))
                    .accessibilityLabel("\(workout.intensity.rawValue) intensity")
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name)
                        .font(.headline)
                    HStack(spacing: 12) {
                        Label("\(workout.durationMinutes) min", systemImage: "clock")
                        Label("\(workout.exercises.count) exercises", systemImage: "list.bullet")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if viewModel.todayCheckIn == nil {
                Button {
                    FeedbackManager.light()
                    AppRoute.dailyCheckIn.apply(to: viewModel, subscriptionManager: subscriptionManager)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "sun.max.fill")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Check in to log how you felt")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            Text("Helps Coach tune tomorrow's plan")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Check in to log how you felt today")
                .accessibilityHint("Opens daily check-in form")
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.30), lineWidth: 1)
        )
    }

    // MARK: - Check-In Trends

    private var checkInTrends: some View {
        let recent = viewModel.recentCheckIns
        let avgEnergy = recent.map(\.energyLevel).reduce(0, +) / max(recent.count, 1)
        let avgSoreness = recent.map(\.sorenessLevel).reduce(0, +) / max(recent.count, 1)
        let tiredDays = recent.filter { $0.mood == .tired || $0.mood == .awful }.count

        return VStack(alignment: .leading, spacing: 10) {
            Button {
                FeedbackManager.light()
                withAnimation { trendsExpanded.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.indigo)
                        .accessibilityHidden(true)
                    Text("Your Trends")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("Last \(recent.count) days")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(trendsExpanded ? 90 : 0))
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Your trends, last \(recent.count) days")
            .accessibilityHint(trendsExpanded ? "Tap to collapse" : "Tap to expand")

            if trendsExpanded {

            // Mood row
            HStack(spacing: 6) {
                ForEach(recent.suffix(7)) { checkIn in
                    VStack(spacing: 3) {
                        Text(checkIn.mood.emoji)
                            .font(.caption)
                        Text(shortDay(checkIn.date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Divider()

            // Summary stats
            HStack(spacing: 0) {
                TrendStat(label: "Avg Energy", value: "\(avgEnergy)/5", icon: "bolt.fill", color: energyColor(avgEnergy))
                    .frame(maxWidth: .infinity)
                TrendStat(label: "Avg Soreness", value: "\(avgSoreness)/5", icon: "figure.flexibility", color: sorenessColor(avgSoreness))
                    .frame(maxWidth: .infinity)
                TrendStat(label: "Tired Days", value: "\(tiredDays)", icon: "moon.zzz.fill", color: tiredDays >= 3 ? .red : .green)
                    .frame(maxWidth: .infinity)
            }

            // Coaching insight
            HStack(spacing: 6) {
                Image(systemName: tiredDays >= 3 ? "exclamationmark.triangle.fill" : avgEnergy >= 4 ? "bolt.circle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(tiredDays >= 3 ? .orange : avgEnergy >= 4 ? .green : .blue)
                    .font(.caption)
                Text(CoachCopy.trendInsight(avgEnergy: avgEnergy, tiredDays: tiredDays, avgSoreness: avgSoreness))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            } // end if trendsExpanded
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
        .onTapGesture {
            if !trendsExpanded {
                FeedbackManager.light()
                withAnimation { trendsExpanded = true }
            }
        }
    }

    private func intensityIcon(_ intensity: Workout.Intensity) -> String {
        switch intensity {
        case .low: return "leaf.fill"
        case .moderate: return "bolt.fill"
        case .high: return "flame.fill"
        }
    }

    private func shortDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func energyColor(_ level: Int) -> Color {
        level >= 4 ? .green : level >= 3 ? .yellow : .orange
    }

    private func sorenessColor(_ level: Int) -> Color {
        level <= 2 ? .green : level <= 3 ? .yellow : .red
    }

    // MARK: - Check-In & Insights

    private var insightsPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                FeedbackManager.light()
                withAnimation { coachNotesExpanded.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile.fill")
                        .foregroundStyle(.purple)
                        .accessibilityHidden(true)
                    Text("Coach's Notes")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    if !viewModel.adaptiveInsights.isEmpty {
                        Text("\(viewModel.adaptiveInsights.count)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple, in: Capsule())
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(coachNotesExpanded ? 90 : 0))
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Coach's Notes, \(viewModel.adaptiveInsights.count) insights")
            .accessibilityHint(coachNotesExpanded ? "Tap to collapse" : "Tap to expand")

            if !subscriptionManager.hasFullAccess {
                Button {
                    FeedbackManager.light()
                    AppRoute.subscription.apply(to: viewModel, subscriptionManager: subscriptionManager)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.purple)
                            .font(.caption)
                            .accessibilityHidden(true)
                        Text("Premium unlocks Coach's Notes that adapt in real time.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                    .padding(.top, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Premium unlocks Coach's Notes")
                .accessibilityHint("Opens premium plans")
            } else if viewModel.adaptiveInsights.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .accessibilityHidden(true)
                        Text("New notes appear as your data grows.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 8) {
                        if !viewModel.healthKit.isAuthorized {
                            Button {
                                FeedbackManager.light()
                                AppRoute.connectHealth.apply(to: viewModel, subscriptionManager: subscriptionManager)
                            } label: {
                                Label("Connect Health", systemImage: "heart.fill")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(.red)
                        }
                        if viewModel.todayCheckIn == nil {
                            Button {
                                FeedbackManager.light()
                                AppRoute.dailyCheckIn.apply(to: viewModel, subscriptionManager: subscriptionManager)
                            } label: {
                                Label("Check In", systemImage: "sun.max.fill")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(.blue)
                        }
                    }
                    .padding(.leading, 22)
                }
                .padding(.top, 4)
            } else {
                // Always show first insight as a preview, even when collapsed
                let visible = coachNotesExpanded ? Array(viewModel.adaptiveInsights.prefix(4)) : Array(viewModel.adaptiveInsights.prefix(1))
                ForEach(visible) { insight in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: insight.icon)
                            .foregroundStyle(Color(insight.color))
                            .frame(width: 20)
                            .accessibilityHidden(true)
                        Text(insight.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(coachNotesExpanded ? nil : 2)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(insight.message)
                }

                if coachNotesExpanded {
                    Divider()
                        .padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "book.fill")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .accessibilityHidden(true)
                            Text("Based on ACSM training guidelines, sleep research, and your tracked data.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Text("AI-generated suggestions. Not medical advice. Consult a professional for health decisions.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
        .onTapGesture {
            if !coachNotesExpanded {
                FeedbackManager.light()
                withAnimation { coachNotesExpanded = true }
            }
        }
    }

    // MARK: - Health

    private var snapshot: HealthSnapshot? { viewModel.effectiveSnapshot }

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                    .accessibilityHidden(true)
                Text("Health")
                    .font(.headline)
                Spacer()
                if viewModel.healthKit.isAuthorized {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption2)
                            .accessibilityHidden(true)
                        Text("Connected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Apple Health connected")
                    Button {
                        FeedbackManager.light()
                        AppRoute.healthManage.apply(to: viewModel, subscriptionManager: subscriptionManager)
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                    .accessibilityLabel("Manage health settings")
                } else if viewModel.manualStats.hasData {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption2)
                            .accessibilityHidden(true)
                        Text("Manual")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Using manual health data")
                    Button {
                        AppRoute.manualHealthStats.apply(to: viewModel, subscriptionManager: subscriptionManager)
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                    .accessibilityLabel("Edit manual health stats")
                }
            }

            if !viewModel.healthKit.isAuthorized && !viewModel.manualStats.hasData {
                let previouslyDenied = viewModel.healthKit.hasPreviouslyDenied
                // Connect prompt — clear CTA with deep linking
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "heart.circle.fill")
                            .font(.title)
                            .foregroundStyle(.red)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(previouslyDenied ? "Health access disabled" : "Connect Apple Health")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(previouslyDenied ? "Enable Health permissions in iOS Settings to sync." : "Sync steps, sleep, and heart rate to personalize your plan.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    HStack(spacing: 10) {
                        Button {
                            FeedbackManager.light()
                            if previouslyDenied {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            } else {
                                AppRoute.connectHealth.apply(to: viewModel, subscriptionManager: subscriptionManager)
                            }
                        } label: {
                            Label(previouslyDenied ? "Open Settings" : "Connect", systemImage: previouslyDenied ? "gear" : "heart.fill")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .controlSize(.regular)
                        .accessibilityHint(previouslyDenied ? "Opens iOS Settings" : "Opens Apple Health authorization")

                        Button {
                            AppRoute.manualHealthStats.apply(to: viewModel, subscriptionManager: subscriptionManager)
                        } label: {
                            Label("Enter Manually", systemImage: "pencil")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        .accessibilityHint("Opens manual stats entry form")
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            } else if viewModel.isLoadingHealthData && snapshot == nil {
                // Loading skeleton while data syncs
                HealthSkeletonRow()
                    .accessibilityLabel("Loading health data")
            } else if viewModel.healthKit.isAuthorized && snapshot == nil {
                // Empty state — authorized but no data yet
                HStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(.blue)
                        .font(.title3)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Syncing your data")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Check back in a few minutes after you've moved around.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            } else if let snap = snapshot {
                let enabled = viewModel.healthKit.enabledMetrics
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        if enabled.contains("steps") {
                            CompactMetricCard(title: "Steps", value: "\(snap.steps)", icon: "figure.walk", color: .green)
                        }
                        if enabled.contains("calories") {
                            CompactMetricCard(title: "Calories", value: "\(Int(snap.caloriesBurned))", icon: "flame.fill", color: .orange)
                        }
                        if enabled.contains("heartRate") {
                            CompactMetricCard(title: "Heart Rate", value: "\(Int(snap.heartRate))", icon: "heart.fill", color: .red, unit: "bpm")
                        }
                        if enabled.contains("sleep") {
                            CompactMetricCard(title: "Sleep", value: String(format: "%.1f", snap.sleepHours), icon: "moon.fill", color: .indigo, unit: "hrs")
                        }
                        if enabled.contains("active") {
                            CompactMetricCard(title: "Active", value: "\(snap.activeMinutes)", icon: "figure.run", color: .blue, unit: "min")
                        }
                        if enabled.contains("restingHeartRate") {
                            CompactMetricCard(title: "Resting HR", value: "\(Int(snap.restingHeartRate))", icon: "waveform.path.ecg", color: .pink, unit: "bpm")
                        }
                        if let w = snap.weight, enabled.contains("weight") {
                            CompactMetricCard(title: "Weight", value: String(format: "%.1f", w), icon: "scalemass.fill", color: .purple, unit: "lbs")
                        }
                        if let bf = snap.bodyFatPercentage, enabled.contains("bodyFat") {
                            CompactMetricCard(title: "Body Fat", value: String(format: "%.1f", bf * 100), icon: "percent", color: .teal, unit: "%")
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

// MARK: - Health Manage Sheet

struct HealthManageSheet: View {
    var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showDisconnectConfirm = false

    private let metrics: [(key: String, title: String, icon: String, color: Color)] = [
        ("steps", "Steps", "figure.walk", .green),
        ("calories", "Active Calories", "flame.fill", .orange),
        ("active", "Exercise Minutes", "figure.run", .blue),
        ("heartRate", "Heart Rate", "heart.fill", .red),
        ("restingHeartRate", "Resting Heart Rate", "waveform.path.ecg", .pink),
        ("sleep", "Sleep", "moon.fill", .indigo),
        ("weight", "Weight", "scalemass.fill", .purple),
        ("bodyFat", "Body Fat %", "percent", .teal),
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Apple Health is connected")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }

                Section {
                    ForEach(metrics, id: \.key) { metric in
                        HStack {
                            Image(systemName: metric.icon)
                                .foregroundStyle(metric.color)
                                .frame(width: 24)
                            Text(metric.title)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { viewModel.healthKit.enabledMetrics.contains(metric.key) },
                                set: { _ in
                                    FeedbackManager.light()
                                    viewModel.healthKit.toggleMetric(metric.key)
                                }
                            ))
                            .labelsHidden()
                        }
                    }
                } header: {
                    Text("Show on Dashboard")
                } footer: {
                    Text("Turn off metrics you don't want to see. Your plan will still adapt to them in the background.")
                }

                Section {
                    Button {
                        Task {
                            await viewModel.healthKit.fetchTodayData()
                            FeedbackManager.success()
                        }
                    } label: {
                        Label("Refresh Data", systemImage: "arrow.clockwise")
                    }

                    Link(destination: URL(string: "x-apple-health://")!) {
                        Label("Open Health App", systemImage: "heart.fill")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showDisconnectConfirm = true
                    } label: {
                        Label("Disconnect Apple Health", systemImage: "xmark.circle")
                    }
                } footer: {
                    Text("To fully revoke permissions, also go to Settings > Health > Data Access & Devices > Longivor.")
                }
            }
            .navigationTitle("Manage Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Disconnect Apple Health?", isPresented: $showDisconnectConfirm, titleVisibility: .visible) {
                Button("Disconnect", role: .destructive) {
                    viewModel.healthKit.disconnect()
                    FeedbackManager.medium()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your plan will use manual stats or defaults instead. You can reconnect anytime.")
            }
        }
    }
}

// MARK: - Progress Hub Sheet (consolidated gamification)

struct ProgressHubSheet: View {
    var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    levelCard
                    streakSection
                    statsGrid
                    achievementsGrid
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Your Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var levelCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.yellow.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: viewModel.rewardProgress.levelProgress)
                    .stroke(Color.yellow, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring, value: viewModel.rewardProgress.levelProgress)
                VStack {
                    Text("LEVEL")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.rewardProgress.level)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
            }
            .frame(width: 100, height: 100)

            Text("\(viewModel.rewardProgress.totalPoints) Total Points")
                .font(.headline)
            Text("\(viewModel.rewardProgress.pointsToNextLevel) pts to next level")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var streakSection: some View {
        VStack(spacing: 12) {
            // Streak header
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            viewModel.streakData.currentStreak > 0
                                ? LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [Color(.systemGray4), Color(.systemGray5)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 56, height: 56)
                    VStack(spacing: 0) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                        Text("\(viewModel.streakData.currentStreak)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(CoachCopy.streakMessage(streak: viewModel.streakData.currentStreak))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    if viewModel.streakData.streakIsAtRisk {
                        Text("Streak at risk! Do something today.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                Spacer()
            }

            // Week calendar
            HStack(spacing: 8) {
                ForEach(weekDays(), id: \.label) { day in
                    VStack(spacing: 4) {
                        Text(day.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        ZStack {
                            Circle()
                                .fill(day.isCompleted ? Color.orange : day.isToday ? Color.blue.opacity(0.2) : Color(.systemGray6))
                                .frame(width: 32, height: 32)
                            if day.isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            } else if day.isToday {
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2)
                                    .frame(width: 32, height: 32)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Streak stats
            HStack(spacing: 0) {
                VStack {
                    Text("\(viewModel.streakData.longestStreak)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Best")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                Divider().frame(height: 30)
                VStack {
                    Text("\(viewModel.streakData.totalActiveDays)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Total Days")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                Divider().frame(height: 30)
                VStack {
                    HStack(spacing: 2) {
                        Image(systemName: "snowflake")
                            .font(.caption)
                            .foregroundStyle(.cyan)
                        Text("\(viewModel.streakData.availableFreezes)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    Text("Freezes")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            if viewModel.streakData.streakIsAtRisk && viewModel.streakData.canUseFreeze {
                Button {
                    viewModel.useStreakFreeze()
                    FeedbackManager.medium()
                } label: {
                    Label("Use Streak Freeze", systemImage: "snowflake")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .controlSize(.regular)
            } else if viewModel.streakData.currentStreak <= 3 && viewModel.streakData.availableFreezes > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "snowflake")
                        .foregroundStyle(.cyan)
                        .font(.caption)
                    Text("You have \(viewModel.streakData.availableFreezes) streak freeze\(viewModel.streakData.availableFreezes == 1 ? "" : "s") to protect your streak on rest days. Earn more every 7 days.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.cyan.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatBadge(title: "Goals Done", value: "\(viewModel.rewardProgress.goalsCompleted)", icon: "trophy.fill", color: .green)
            StatBadge(title: "Milestones", value: "\(viewModel.rewardProgress.milestonesReached)", icon: "flag.fill", color: .blue)
        }
    }

    private var achievementsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.rewardProgress.rewards) { reward in
                    RewardBadge(reward: reward)
                }
            }
        }
    }

    // MARK: - Week Day Helper

    private struct WeekDay {
        let label: String
        let isCompleted: Bool
        let isToday: Bool
    }

    private func weekDays() -> [WeekDay] {
        let calendar = Calendar.current
        let today = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else { return [] }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: weekInterval.start)!
            let isToday = calendar.isDateInToday(date)
            let isCompleted = viewModel.streakData.weeklyCompletions.contains { calendar.isDate($0, inSameDayAs: date) }
            return WeekDay(label: formatter.string(from: date), isCompleted: isCompleted, isToday: isToday)
        }
    }
}

// MARK: - Compact Metric Card

struct CompactMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var unit: String? = nil

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            HStack(spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                if let unit {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 80, minHeight: 80)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)\(unit.map { " \($0)" } ?? "")")
    }
}

// MARK: - Trend Stat

struct TrendStat: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

