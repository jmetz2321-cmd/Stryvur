import SwiftUI

struct DashboardView: View {
    var viewModel: AppViewModel
    var authManager: AuthManager
    @State private var showHealthPermissions = false
    @State private var showManualStats = false
    @State private var showSignOutConfirm = false
    @State private var showProgressHub = false
    @State private var quickGoalValue: String = ""
    @State private var workoutJustCompleted = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    heroCard
                    if !setupComplete {
                        setupChecklist
                    }
                    progressHubCard
                    if viewModel.todayCheckIn == nil {
                        checkInPrompt
                    }
                    if let workout = viewModel.todayWorkout {
                        todayWorkoutCard(workout)
                    }
                    if !viewModel.adaptiveInsights.isEmpty {
                        insightsPreview
                    }
                    if !viewModel.recentCheckIns.isEmpty && viewModel.recentCheckIns.count >= 3 {
                        checkInTrends
                    }
                    if snapshot != nil || !viewModel.healthKit.isAuthorized {
                        healthSection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("4ever Health")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        if !authManager.userName.isEmpty {
                            Label(authManager.userName, systemImage: "person.fill")
                        }
                        if !authManager.userEmail.isEmpty {
                            Label(authManager.userEmail, systemImage: "envelope.fill")
                        }
                        Divider()
                        Button(role: .destructive) {
                            showSignOutConfirm = true
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
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
                    await viewModel.healthKit.fetchTodayData()
                }
                viewModel.adaptAllPlans()
            }
            .refreshable {
                await viewModel.healthKit.fetchTodayData()
                viewModel.adaptAllPlans()
            }
            .sheet(isPresented: $showHealthPermissions) {
                HealthPermissionsSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showManualStats) {
                ManualStatsSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showProgressHub) {
                ProgressHubSheet(viewModel: viewModel)
            }
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(coachGreeting)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Spacer()
            }

            if let primary = viewModel.goals.first(where: { !$0.isCompleted }) {
                Divider()
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .stroke(Color(primary.category.color).opacity(0.15), lineWidth: 6)
                        Circle()
                            .trim(from: 0, to: primary.progress)
                            .stroke(Color(primary.category.color), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.spring, value: primary.progress)
                        Text("\(Int(primary.progress * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(primary.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(CoachCopy.goalEncouragement(progress: primary.progress, title: primary.title))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: primary.category.icon)
                        .font(.title3)
                        .foregroundStyle(Color(primary.category.color))
                }

                // Quick progress log
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil.line")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        TextField("Log \(primary.unit)", text: $quickGoalValue)
                            .font(.caption)
                            .keyboardType(.decimalPad)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))

                    Button {
                        if let value = Double(quickGoalValue) {
                            viewModel.updateGoalProgress(primary.id, newValue: value)
                            quickGoalValue = ""
                        }
                    } label: {
                        Text("Log")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(quickGoalValue.isEmpty)
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
                Divider()
                HStack(spacing: 10) {
                    Image(systemName: "target")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    Text(CoachCopy.noGoalsYet())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Divider()
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
            showProgressHub = true
        } label: {
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
            .background(
                LinearGradient(
                    colors: [Color.yellow.opacity(0.06), Color.orange.opacity(0.04)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.yellow.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Today's Workout

    private func todayWorkoutCard(_ workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(.blue)
                Text(CoachCopy.todayWorkoutTitle(workout.name))
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
            }

            HStack(spacing: 14) {
                Button {
                    FeedbackManager.light()
                    viewModel.expandWorkoutId = workout.id
                    viewModel.selectedTab = 1
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(workout.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 12) {
                            Label("\(workout.durationMinutes) min", systemImage: "clock")
                            Label("\(workout.exercises.count) exercises", systemImage: "list.bullet")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                Spacer()
                Button {
                    viewModel.completeWorkout(workout.id)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        workoutJustCompleted = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        workoutJustCompleted = false
                    }
                } label: {
                    Text("Done")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .scaleEffect(workoutJustCompleted ? 1.15 : 1.0)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Check-In Trends

    private var checkInTrends: some View {
        let recent = viewModel.recentCheckIns
        let avgEnergy = recent.map(\.energyLevel).reduce(0, +) / max(recent.count, 1)
        let avgSoreness = recent.map(\.sorenessLevel).reduce(0, +) / max(recent.count, 1)
        let tiredDays = recent.filter { $0.mood == .tired || $0.mood == .awful }.count

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.indigo)
                Text("Your Trends")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("Last \(recent.count) days")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Mood row
            HStack(spacing: 6) {
                ForEach(recent.suffix(7)) { checkIn in
                    VStack(spacing: 3) {
                        Text(checkIn.mood.emoji)
                            .font(.caption)
                        Text(shortDay(checkIn.date))
                            .font(.system(size: 8))
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
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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

    // MARK: - Setup

    private var hasGoal: Bool { !viewModel.goals.isEmpty }
    private var healthConnected: Bool { viewModel.healthKit.isAuthorized }
    private var hasCheckedIn: Bool { viewModel.todayCheckIn != nil }
    private var setupComplete: Bool { hasGoal && healthConnected }

    private var remainingSteps: [(step: Int, view: AnyView)] {
        var steps: [(step: Int, view: AnyView)] = []
        if !hasGoal {
            steps.append((1, AnyView(
                SetupStepRow(step: steps.count + 1, title: "Set a Fitness Goal", subtitle: "Go to the Goals tab and create your first goal.", isComplete: false, icon: "target")
            )))
        }
        if !healthConnected {
            steps.append((2, AnyView(
                VStack(alignment: .leading, spacing: 8) {
                    SetupStepRow(step: steps.count + 1, title: "Connect Apple Health", subtitle: "Allow access to steps, sleep, heart rate, and more.", isComplete: false, icon: "heart.fill")
                    Button {
                        Task { await viewModel.healthKit.requestAuthorization() }
                    } label: {
                        Label("Connect Apple Health", systemImage: "heart.circle.fill")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.small)
                    .padding(.leading, 40)
                }
            )))
        }
        return steps
    }

    private var setupChecklist: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "list.clipboard.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Let's Get You Set Up")
                        .font(.headline)
                    Text("A couple quick steps and you'll have a personalized plan.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(Array(remainingSteps.enumerated()), id: \.element.step) { _, item in
                item.view
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Check-In & Insights

    private var checkInPrompt: some View {
        Button {
            FeedbackManager.light()
            viewModel.showMorningCheckIn = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sun.max.fill")
                    .font(.title3)
                    .foregroundStyle(.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Check-In")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(CoachCopy.checkInPrompt())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.yellow.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var insightsPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile.fill")
                    .foregroundStyle(.purple)
                Text("Coach's Notes")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            ForEach(viewModel.adaptiveInsights.prefix(2)) { insight in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: insight.icon)
                        .foregroundStyle(Color(insight.color))
                        .frame(width: 20)
                    Text(insight.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Text("AI-generated \u{2022} Not medical advice")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Health

    private var snapshot: HealthSnapshot? { viewModel.effectiveSnapshot }

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                Text("Health")
                    .font(.headline)
                Spacer()
                if viewModel.healthKit.isAuthorized {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        Text("Connected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        showHealthPermissions = true
                    } label: {
                        Image(systemName: "gear")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button {
                        Task { await viewModel.healthKit.requestAuthorization() }
                    } label: {
                        Label("Connect", systemImage: "heart.circle.fill")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.small)
                }
                Button {
                    showManualStats = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }

            if let snap = snapshot {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CompactMetricCard(title: "Steps", value: "\(snap.steps)", icon: "figure.walk", color: .green)
                        CompactMetricCard(title: "Calories", value: "\(Int(snap.caloriesBurned))", icon: "flame.fill", color: .orange)
                        CompactMetricCard(title: "Heart Rate", value: "\(Int(snap.heartRate))", icon: "heart.fill", color: .red, unit: "bpm")
                        CompactMetricCard(title: "Sleep", value: String(format: "%.1f", snap.sleepHours), icon: "moon.fill", color: .indigo, unit: "hrs")
                        CompactMetricCard(title: "Active", value: "\(snap.activeMinutes)", icon: "figure.run", color: .blue, unit: "min")
                        CompactMetricCard(title: "Resting HR", value: "\(Int(snap.restingHeartRate))", icon: "waveform.path.ecg", color: .pink, unit: "bpm")
                        if let w = snap.weight {
                            CompactMetricCard(title: "Weight", value: String(format: "%.1f", w), icon: "scalemass.fill", color: .purple, unit: "lbs")
                        }
                        if let bf = snap.bodyFatPercentage {
                            CompactMetricCard(title: "Body Fat", value: String(format: "%.1f", bf * 100), icon: "percent", color: .teal, unit: "%")
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            if !viewModel.healthKit.isAuthorized && viewModel.manualStats.hasData {
                HStack {
                    Image(systemName: "hand.draw.fill")
                        .foregroundStyle(.secondary)
                    Text("Using manually entered stats")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
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
        .frame(width: 80, height: 80)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
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
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Supporting Views

struct SetupStepRow: View {
    let step: Int
    let title: String
    let subtitle: String
    let isComplete: Bool
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(isComplete ? .green : Color(.systemGray5))
                    .frame(width: 28, height: 28)
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                } else {
                    Text("\(step)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(isComplete ? .green : .blue)
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .strikethrough(isComplete)
                        .foregroundStyle(isComplete ? .secondary : .primary)
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
