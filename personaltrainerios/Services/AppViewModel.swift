import Foundation
import SwiftUI
import Observation

@Observable
class AppViewModel {
    var goals: [UserGoal] = []
    var trainingPlan: TrainingPlan?
    var rewardProgress: RewardProgress
    var functionHealthVitals: FunctionHealthVitals?
    var showCelebration = false
    var celebrationMessage = ""

    var todayCheckIn: DailyCheckIn?
    var checkInHistory: [DailyCheckIn] = []
    var streakData: StreakData
    var adaptiveInsights: [AdaptiveInsight] = []
    var showMorningCheckIn = false
    var integrationStatus: HealthIntegrationStatus

    var manualStats: ManualHealthStats = ManualHealthStats()
    var foodLog: [FoodLogEntry] = []
    var checkedMeals: Set<String> = []
    var todayWaterOz: Int = 0
    var workoutHistory: [WorkoutHistoryEntry] = []

    var userId: String = ""
    var expandWorkoutId: UUID?
    var selectedTab: Int = 0
    /// Routes the Plan tab to a specific segment when set externally (e.g. via notification tap).
    /// Values: "workouts", "nutrition", "sleep"
    var planSegmentRoute: String?
    var lastCompletedWorkoutId: UUID?
    var showUndoToast: Bool = false
    var undoToastMessage: String = ""

    // "Plan updated" feedback toast (separate from undo toast)
    var showPlanUpdatedToast: Bool = false
    var planUpdatedMessage: String = ""

    // Top-level sheet routing (presented by MainTabView to avoid toolbar/sheet race)
    var activeSheet: DashboardSheet?
    var showFirstRunTour: Bool = false
    var showRateAppPrompt: Bool = false

    // Progressive disclosure & UX improvements
    var isLoadingHealthData = false
    var healthSyncError: String?
    var deepLinkRoute: AppRoute?

    enum DashboardSheet: String, Identifiable {
        case manualStats, progressHub, healthManage, help, paywall
        var id: String { rawValue }
    }

    let healthKit = HealthKitManager()
    let functionHealth = FunctionHealthService()

    var effectiveSnapshot: HealthSnapshot? {
        if healthKit.isAuthorized, let snapshot = healthKit.todaySnapshot {
            return snapshot
        }
        if manualStats.hasData {
            return manualStats.toSnapshot()
        }
        return nil
    }

    // MARK: - Progressive Disclosure (Day-based visibility)

    private var daysSinceFirstLaunch: Int {
        guard let firstLaunchDate = UserDefaults.standard.object(forKey: "appFirstLaunchDate") as? Date else {
            return 0
        }
        let days = Calendar.current.dateComponents([.day], from: firstLaunchDate, to: Date()).day ?? 0
        return max(0, days)
    }

    var shouldShowTrendsSection: Bool {
        checkInHistory.count >= 3 && daysSinceFirstLaunch >= 2
    }

    var shouldShowCoachNotesSection: Bool {
        // Always show — internal empty state guides user to connect health / check in
        true
    }

    var shouldShowProgressHub: Bool {
        daysSinceFirstLaunch >= 3
    }

    var shouldShowGettingStartedCard: Bool {
        let hasHealth = healthKit.isAuthorized || manualStats.hasData
        return !hasHealth && daysSinceFirstLaunch <= 2
    }

    var shouldShowTrialReminderCard: Bool {
        daysSinceFirstLaunch >= 4
    }

    init() {
        self.rewardProgress = RewardProgress(
            totalPoints: 0,
            currentStreak: 0,
            longestStreak: 0,
            goalsCompleted: 0,
            milestonesReached: 0,
            rewards: Self.defaultRewards()
        )
        self.streakData = StreakData()
        self.integrationStatus = HealthIntegrationStatus()
        loadSavedData()
        // Record first-open day for greeting fatigue tracking
        if UserDefaults.standard.integer(forKey: "firstOpenDayOfYear") == 0 {
            let today = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
            UserDefaults.standard.set(today, forKey: "firstOpenDayOfYear")
        }
        // Record first launch date for progressive disclosure
        if UserDefaults.standard.object(forKey: "appFirstLaunchDate") == nil {
            UserDefaults.standard.set(Date(), forKey: "appFirstLaunchDate")
        }
        checkMorningCheckIn()
    }

    // MARK: - Morning Check-In

    func submitCheckIn(_ checkIn: DailyCheckIn) {
        todayCheckIn = checkIn
        checkInHistory.append(checkIn)
        rewardProgress.totalPoints += 10
        FeedbackManager.medium()
        BehaviorTracker.record(.checkIn)

        adaptAllPlans()
        recordStreakActivity()
        triggerPlanUpdated("Plan updated based on your check-in")

        saveData()
    }

    func adaptAllPlans() {
        adaptTrainingPlan()
        adjustNutritionForStats()
        refreshInsights()
        refreshNotifications()
    }

    func refreshNotifications() {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let today = formatter.string(from: Date())
        let todayWorkout = trainingPlan?.workouts.first(where: { $0.day == today && !$0.isCompleted })

        NotificationManager.scheduleAllNotifications(
            streak: streakData.currentStreak,
            hasCheckedInToday: todayCheckIn != nil,
            todayWorkoutName: todayWorkout?.name,
            caloriesLogged: todayLoggedCalories,
            calorieTarget: trainingPlan?.nutritionPlan.dailyCalories ?? 0,
            waterOz: todayWaterOz,
            waterTarget: trainingPlan?.nutritionPlan.hydrationOz ?? 0
        )

        // If user already checked in or completed a workout today, cancel the streak-at-risk nag
        if todayCheckIn != nil || trainingPlan?.workouts.contains(where: { $0.day == today && $0.isCompleted }) == true {
            NotificationManager.cancelStreakAtRisk()
        }
    }

    private func checkMorningCheckIn() {
        // No longer auto-presents — check-in is surfaced via the Dashboard card instead.
        // Users still tap to open the check-in sheet when they're ready.
    }

    // MARK: - Food Log

    func addFoodLogEntry(_ entry: FoodLogEntry) {
        foodLog.append(entry)
        BehaviorTracker.record(.mealLog)
        refreshInsights()
        triggerPlanUpdated("Coach's Notes updated")

        // Show rate prompt on first nutrition log entry
        if !UserDefaults.standard.bool(forKey: "hasSeenRatePrompt") && foodLog.count == 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showRateAppPrompt = true
                UserDefaults.standard.set(true, forKey: "hasSeenRatePrompt")
            }
        }

        saveData()
    }

    func removeFoodLogEntry(_ id: UUID) {
        foodLog.removeAll { $0.id == id }
        refreshInsights()
        saveData()
    }

    func toggleMealChecked(_ mealId: String) {
        if checkedMeals.contains(mealId) {
            checkedMeals.remove(mealId)
        } else {
            checkedMeals.insert(mealId)
            FeedbackManager.light()
        }
        checkNutritionRewards()
        refreshInsights()
        saveData()
    }

    var todayFoodLog: [FoodLogEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return foodLog.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: today) }
    }

    var checkedMealCalories: Int {
        guard let meals = trainingPlan?.nutritionPlan.meals else { return 0 }
        return meals.filter { checkedMeals.contains($0.id.uuidString) }
            .reduce(0) { $0 + $1.calories }
    }

    var todayLoggedCalories: Int {
        todayFoodLog.reduce(0) { $0 + $1.calories } + checkedMealCalories
    }

    // MARK: - Hydration

    func addWater(_ oz: Int = 8) {
        todayWaterOz += oz
        FeedbackManager.soft()
        BehaviorTracker.record(.waterLog)
        checkHydrationReward()
        refreshInsights()
        saveData()
    }

    func removeWater(_ oz: Int = 8) {
        todayWaterOz = max(todayWaterOz - oz, 0)
        refreshInsights()
        saveData()
    }

    private func checkNutritionRewards() {
        guard let plan = trainingPlan?.nutritionPlan else { return }
        if todayLoggedCalories > 0 && todayLoggedCalories <= plan.dailyCalories {
            let key = "calorieReward_\(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)"
            if !UserDefaults.standard.bool(forKey: key) {
                // Check if all meals are checked
                let allChecked = plan.meals.allSatisfy { checkedMeals.contains($0.id.uuidString) }
                if allChecked {
                    rewardProgress.totalPoints += 20
                    triggerCelebration("All meals logged and under calorie target! +20 pts")
                    UserDefaults.standard.set(true, forKey: key)
                    recordStreakActivity()
                }
            }
        }
    }

    private func checkHydrationReward() {
        guard let plan = trainingPlan?.nutritionPlan else { return }
        if todayWaterOz >= plan.hydrationOz {
            let key = "hydrationReward_\(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)"
            if !UserDefaults.standard.bool(forKey: key) {
                rewardProgress.totalPoints += 10
                triggerCelebration("Hydration target hit! +10 pts")
                UserDefaults.standard.set(true, forKey: key)
            }
        }
    }

    // MARK: - Today's Workout

    /// Today's workout that hasn't been completed yet. Nil if no workout scheduled or already done.
    var todayWorkout: Workout? {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let today = formatter.string(from: Date())
        return trainingPlan?.workouts.first(where: { $0.day == today && !$0.isCompleted })
    }

    /// Today's workout regardless of completion status. Used to distinguish rest days from done-workout days.
    var todayScheduledWorkout: Workout? {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let today = formatter.string(from: Date())
        return trainingPlan?.workouts.first(where: { $0.day == today })
    }

    /// True if today's scheduled workout is "Active Recovery" (Recovery Day, not Rest Day).
    var isTodayRecoveryDay: Bool {
        guard let workout = todayScheduledWorkout else { return false }
        return workout.name.localizedCaseInsensitiveContains("recovery")
    }

    /// True if today has no scheduled workout at all (true Rest Day).
    var isTodayRestDay: Bool {
        todayScheduledWorkout == nil
    }

    /// True if today's scheduled workout has been completed.
    var isTodayWorkoutCompleted: Bool {
        todayScheduledWorkout?.isCompleted ?? false
    }

    // MARK: - Check-In Trends (last 7 days)

    var recentCheckIns: [DailyCheckIn] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return checkInHistory
            .filter { $0.date >= sevenDaysAgo }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Manual Stats Entry

    func updateManualStats(_ stats: ManualHealthStats) {
        manualStats = stats
        manualStats.lastUpdated = Date()
        adaptAllPlans()
        saveData()
    }

    // MARK: - AI Plan Adaptation

    func adaptTrainingPlan() {
        guard var plan = trainingPlan else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let today = formatter.string(from: Date())

        // Adapt today's specific workout based on check-in + health
        plan.workouts = plan.workouts.map { workout in
            if workout.day == today && !workout.isCompleted {
                return AdaptiveEngine.adaptWorkout(workout, checkIn: todayCheckIn, healthSnapshot: effectiveSnapshot)
            }
            return workout
        }

        // Adapt all remaining weekly workouts based on trends
        plan.workouts = AdaptiveEngine.adaptWeeklyPlan(plan.workouts, checkInHistory: checkInHistory, healthSnapshot: effectiveSnapshot)

        trainingPlan = plan
    }

    func adjustNutritionForStats() {
        guard var plan = trainingPlan else { return }
        let primaryGoal = goals.first(where: { !$0.isCompleted })

        // Use the full adaptive nutrition engine
        plan.nutritionPlan = AdaptiveEngine.adaptNutrition(
            plan.nutritionPlan,
            checkIn: todayCheckIn,
            healthSnapshot: effectiveSnapshot,
            goal: primaryGoal
        )

        // Adapt sleep recommendation too
        plan.sleepRecommendation = AdaptiveEngine.adaptSleep(
            plan.sleepRecommendation,
            checkIn: todayCheckIn,
            healthSnapshot: effectiveSnapshot
        )

        trainingPlan = plan
    }

    func refreshInsights() {
        let isWeightLoss = goals.first(where: { !$0.isCompleted })?.category == .weightLoss
        adaptiveInsights = AdaptiveEngine.generateInsights(
            checkIn: todayCheckIn,
            healthSnapshot: effectiveSnapshot,
            functionVitals: functionHealth.vitals,
            streakData: streakData,
            caloriesLogged: todayLoggedCalories,
            calorieTarget: trainingPlan?.nutritionPlan.dailyCalories ?? 0,
            waterOz: todayWaterOz,
            waterTarget: trainingPlan?.nutritionPlan.hydrationOz ?? 0,
            isWeightLossGoal: isWeightLoss
        )
    }

    // MARK: - Streak System

    func recordStreakActivity() {
        let now = Date()

        if let last = streakData.lastActivityDate,
           Calendar.current.isDate(last, inSameDayAs: now) {
            return
        }

        if let last = streakData.lastActivityDate {
            let daysBetween = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: last), to: Calendar.current.startOfDay(for: now)).day ?? 0
            if daysBetween > 1 {
                streakData.currentStreak = 0
            }
        }

        streakData.currentStreak += 1
        streakData.totalActiveDays += 1
        streakData.lastActivityDate = now
        streakData.weeklyCompletions.append(now)

        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        streakData.weeklyCompletions = streakData.weeklyCompletions.filter { $0 >= oneWeekAgo }

        if streakData.currentStreak > streakData.longestStreak {
            streakData.longestStreak = streakData.currentStreak
        }

        if streakData.currentStreak > 0 && streakData.currentStreak % 7 == 0 {
            streakData.streakFreezes += 1
            triggerCelebration("\(streakData.currentStreak)-day streak! You earned a streak freeze!")
        }

        rewardProgress.currentStreak = streakData.currentStreak
        rewardProgress.longestStreak = streakData.longestStreak

        saveData()
    }

    func useStreakFreeze() {
        guard streakData.canUseFreeze else { return }
        streakData.freezesUsed += 1
        streakData.lastActivityDate = Date()
        saveData()
    }

    // MARK: - Goals

    func addGoal(_ goal: UserGoal) {
        var goalWithMilestones = goal
        goalWithMilestones.milestones = generateMilestones(for: goal)
        goals.append(goalWithMilestones)
        generateTrainingPlan()
        saveData()
    }

    func updateGoal(_ updated: UserGoal) {
        guard let index = goals.firstIndex(where: { $0.id == updated.id }) else { return }
        var goal = updated
        goal.milestones = generateMilestones(for: goal)
        goal.isCompleted = goal.hasReachedGoal
        goals[index] = goal
        generateTrainingPlan()
        saveData()
    }

    func removeGoal(_ goalId: UUID) {
        goals.removeAll { $0.id == goalId }
        if goals.isEmpty {
            trainingPlan = nil
        } else {
            generateTrainingPlan()
        }
        saveData()
    }

    func updateGoalProgress(_ goalId: UUID, newValue: Double) {
        guard let index = goals.firstIndex(where: { $0.id == goalId }) else { return }
        let goal = goals[index]
        goals[index].currentValue = newValue
        goals[index].progressHistory.append(ProgressEntry(value: newValue))

        let isDecreasing = goal.category.isDecreasing

        for i in goals[index].milestones.indices {
            let milestoneVal = goals[index].milestones[i].targetValue
            let reached = isDecreasing ? (newValue <= milestoneVal) : (newValue >= milestoneVal)
            if !goals[index].milestones[i].isReached && reached {
                goals[index].milestones[i].isReached = true
                rewardProgress.milestonesReached += 1
                rewardProgress.totalPoints += 25
                triggerCelebration(CoachCopy.milestoneReached(goals[index].milestones[i].title))
            }
        }

        if !goals[index].isCompleted && goals[index].hasReachedGoal {
            goals[index].isCompleted = true
            rewardProgress.goalsCompleted += 1
            rewardProgress.totalPoints += 100
            unlockReward(category: .goalComplete)
            triggerCelebration(CoachCopy.goalCompleted(goals[index].title))
        }

        let madeProgress = isDecreasing ? (newValue < goal.currentValue) : (newValue > goal.currentValue)
        if madeProgress {
            rewardProgress.totalPoints += 5
            recordStreakActivity()
        }

        checkAndUnlockRewards()
        saveData()
    }

    func completeWorkout(_ workoutId: UUID) {
        guard var plan = trainingPlan,
              let index = plan.workouts.firstIndex(where: { $0.id == workoutId }) else { return }
        let name = plan.workouts[index].name
        let historyEntry = WorkoutHistoryEntry(from: plan.workouts[index])
        workoutHistory.append(historyEntry)
        plan.workouts[index].isCompleted = true
        trainingPlan = plan
        rewardProgress.totalPoints += 15
        FeedbackManager.medium()
        BehaviorTracker.record(.workout)
        recordStreakActivity()
        checkAndUnlockRewards()

        // Show undo toast for routine completions; celebration only fires for milestones (streak %7, etc.)
        lastCompletedWorkoutId = workoutId
        undoToastMessage = CoachCopy.workoutCompleted(name)
        showUndoToast = true

        // Show rate prompt on first workout completion
        if !UserDefaults.standard.bool(forKey: "hasSeenRatePrompt") && workoutHistory.count == 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showRateAppPrompt = true
                UserDefaults.standard.set(true, forKey: "hasSeenRatePrompt")
            }
        }

        saveData()
    }

    func undoLastWorkout() {
        guard let workoutId = lastCompletedWorkoutId,
              var plan = trainingPlan,
              let index = plan.workouts.firstIndex(where: { $0.id == workoutId }) else { return }
        plan.workouts[index].isCompleted = false
        trainingPlan = plan
        rewardProgress.totalPoints = max(0, rewardProgress.totalPoints - 15)
        // Remove the most recent history entry matching this workout
        if let historyIndex = workoutHistory.lastIndex(where: { $0.workoutId == workoutId }) {
            workoutHistory.remove(at: historyIndex)
        }
        lastCompletedWorkoutId = nil
        showUndoToast = false
        FeedbackManager.light()
        saveData()
    }

    // MARK: - Training Plan Generation

    func generateTrainingPlan() {
        guard !goals.isEmpty else { return }
        let primaryGoal = goals.first!

        let workouts = generateWorkouts(for: primaryGoal)
        let nutrition = generateNutrition(for: primaryGoal)
        let sleep = generateSleepRec(for: primaryGoal)

        trainingPlan = TrainingPlan(
            weekNumber: 1,
            workouts: workouts,
            nutritionPlan: nutrition,
            sleepRecommendation: sleep
        )

        adaptAllPlans()
    }

    private func generateWorkouts(for goal: UserGoal) -> [Workout] {
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

        switch goal.category {
        case .weightLoss:
            return [
                Workout(name: "HIIT Cardio", day: days[0], exercises: [
                    Exercise(name: "Burpees", sets: 4, reps: "15", restSeconds: 30),
                    Exercise(name: "Mountain Climbers", sets: 4, reps: "20", restSeconds: 30),
                    Exercise(name: "Jump Squats", sets: 4, reps: "15", restSeconds: 30),
                    Exercise(name: "High Knees", sets: 4, reps: "30 sec", restSeconds: 30),
                ], durationMinutes: 35, intensity: .high),
                Workout(name: "Strength Training", day: days[2], exercises: [
                    Exercise(name: "Squats", sets: 4, reps: "12"),
                    Exercise(name: "Push-ups", sets: 3, reps: "15"),
                    Exercise(name: "Lunges", sets: 3, reps: "12 each"),
                    Exercise(name: "Plank", sets: 3, reps: "45 sec"),
                ], durationMinutes: 45, intensity: .moderate),
                Workout(name: "Active Recovery", day: days[4], exercises: [
                    Exercise(name: "Walking", sets: 1, reps: "30 min"),
                    Exercise(name: "Stretching", sets: 1, reps: "15 min"),
                    Exercise(name: "Foam Rolling", sets: 1, reps: "10 min"),
                ], durationMinutes: 55, intensity: .low),
                Workout(name: "Cardio Endurance", day: days[5], exercises: [
                    Exercise(name: "Running/Jogging", sets: 1, reps: "25 min"),
                    Exercise(name: "Cycling", sets: 1, reps: "20 min"),
                ], durationMinutes: 45, intensity: .moderate),
            ]
        case .muscleGain:
            return [
                Workout(name: "Upper Body Push", day: days[0], exercises: [
                    Exercise(name: "Bench Press", sets: 4, reps: "8-10"),
                    Exercise(name: "Overhead Press", sets: 4, reps: "8-10"),
                    Exercise(name: "Incline Dumbbell Press", sets: 3, reps: "10-12"),
                    Exercise(name: "Tricep Dips", sets: 3, reps: "12"),
                ], durationMinutes: 60, intensity: .high),
                Workout(name: "Lower Body", day: days[1], exercises: [
                    Exercise(name: "Barbell Squats", sets: 4, reps: "8-10"),
                    Exercise(name: "Romanian Deadlifts", sets: 4, reps: "10"),
                    Exercise(name: "Leg Press", sets: 3, reps: "12"),
                    Exercise(name: "Calf Raises", sets: 4, reps: "15"),
                ], durationMinutes: 60, intensity: .high),
                Workout(name: "Upper Body Pull", day: days[3], exercises: [
                    Exercise(name: "Pull-ups", sets: 4, reps: "8-10"),
                    Exercise(name: "Barbell Rows", sets: 4, reps: "8-10"),
                    Exercise(name: "Face Pulls", sets: 3, reps: "15"),
                    Exercise(name: "Bicep Curls", sets: 3, reps: "12"),
                ], durationMinutes: 60, intensity: .high),
                Workout(name: "Full Body", day: days[5], exercises: [
                    Exercise(name: "Deadlifts", sets: 4, reps: "6-8"),
                    Exercise(name: "Dumbbell Lunges", sets: 3, reps: "10 each"),
                    Exercise(name: "Push-ups", sets: 3, reps: "15"),
                    Exercise(name: "Plank", sets: 3, reps: "60 sec"),
                ], durationMinutes: 55, intensity: .moderate),
            ]
        default:
            return [
                Workout(name: "Full Body Workout", day: days[0], exercises: [
                    Exercise(name: "Squats", sets: 3, reps: "12"),
                    Exercise(name: "Push-ups", sets: 3, reps: "12"),
                    Exercise(name: "Rows", sets: 3, reps: "12"),
                    Exercise(name: "Plank", sets: 3, reps: "30 sec"),
                ], durationMinutes: 40, intensity: .moderate),
                Workout(name: "Cardio Day", day: days[2], exercises: [
                    Exercise(name: "Running", sets: 1, reps: "20 min"),
                    Exercise(name: "Jump Rope", sets: 3, reps: "3 min"),
                    Exercise(name: "Stretching", sets: 1, reps: "10 min"),
                ], durationMinutes: 40, intensity: .moderate),
                Workout(name: "Flexibility & Core", day: days[4], exercises: [
                    Exercise(name: "Yoga Flow", sets: 1, reps: "20 min"),
                    Exercise(name: "Core Circuit", sets: 3, reps: "10 each"),
                    Exercise(name: "Hip Openers", sets: 1, reps: "10 min"),
                ], durationMinutes: 40, intensity: .low),
            ]
        }
    }

    private func generateNutrition(for goal: UserGoal) -> NutritionPlan {
        switch goal.category {
        case .weightLoss:
            return NutritionPlan(
                dailyCalories: 1800,
                proteinGrams: 140,
                carbsGrams: 160,
                fatGrams: 60,
                meals: [
                    Meal(name: "Breakfast", time: "7:30 AM", foods: ["Egg whites & spinach", "Oatmeal", "Berries"], calories: 350),
                    Meal(name: "Lunch", time: "12:00 PM", foods: ["Grilled chicken salad", "Quinoa", "Avocado"], calories: 500),
                    Meal(name: "Snack", time: "3:30 PM", foods: ["Greek yogurt", "Almonds"], calories: 200),
                    Meal(name: "Dinner", time: "6:30 PM", foods: ["Salmon", "Sweet potato", "Broccoli"], calories: 550),
                    Meal(name: "Evening Snack", time: "8:30 PM", foods: ["Protein shake"], calories: 200),
                ],
                hydrationOz: 80
            )
        case .muscleGain:
            return NutritionPlan(
                dailyCalories: 2800,
                proteinGrams: 200,
                carbsGrams: 300,
                fatGrams: 90,
                meals: [
                    Meal(name: "Breakfast", time: "7:00 AM", foods: ["Whole eggs & toast", "Banana", "Orange juice"], calories: 600),
                    Meal(name: "Pre-Workout", time: "10:30 AM", foods: ["Protein bar", "Apple"], calories: 350),
                    Meal(name: "Post-Workout", time: "1:00 PM", foods: ["Protein shake", "Rice cakes", "Peanut butter"], calories: 500),
                    Meal(name: "Lunch", time: "3:00 PM", foods: ["Steak", "Brown rice", "Mixed veggies"], calories: 650),
                    Meal(name: "Dinner", time: "7:00 PM", foods: ["Chicken breast", "Pasta", "Side salad"], calories: 600),
                    Meal(name: "Before Bed", time: "9:30 PM", foods: ["Casein protein", "Peanut butter"], calories: 300),
                ],
                hydrationOz: 100
            )
        default:
            return NutritionPlan(
                dailyCalories: 2200,
                proteinGrams: 150,
                carbsGrams: 220,
                fatGrams: 75,
                meals: [
                    Meal(name: "Breakfast", time: "7:30 AM", foods: ["Eggs", "Whole grain toast", "Fruit"], calories: 450),
                    Meal(name: "Lunch", time: "12:00 PM", foods: ["Lean protein", "Whole grains", "Vegetables"], calories: 600),
                    Meal(name: "Snack", time: "3:30 PM", foods: ["Trail mix", "Fruit"], calories: 250),
                    Meal(name: "Dinner", time: "6:30 PM", foods: ["Fish/chicken", "Sweet potato", "Greens"], calories: 600),
                    Meal(name: "Evening", time: "8:30 PM", foods: ["Greek yogurt", "Berries"], calories: 200),
                ],
                hydrationOz: 72
            )
        }
    }

    private func generateSleepRec(for goal: UserGoal) -> SleepRecommendation {
        switch goal.category {
        case .muscleGain:
            return SleepRecommendation(
                targetHours: 8.5,
                bedtime: "10:00 PM",
                wakeTime: "6:30 AM",
                tips: [
                    "Sleep is critical for muscle recovery and growth hormone release",
                    "Avoid screens 1 hour before bed",
                    "Keep room temperature between 65-68\u{00B0}F",
                    "Consider magnesium supplement before bed",
                ]
            )
        case .weightLoss:
            return SleepRecommendation(
                targetHours: 7.5,
                bedtime: "10:30 PM",
                wakeTime: "6:00 AM",
                tips: [
                    "Poor sleep increases hunger hormones (ghrelin)",
                    "Consistent sleep schedule supports metabolism",
                    "Avoid eating 2-3 hours before bedtime",
                    "Morning sunlight helps regulate circadian rhythm",
                ]
            )
        default:
            return SleepRecommendation(
                targetHours: 8.0,
                bedtime: "10:30 PM",
                wakeTime: "6:30 AM",
                tips: [
                    "Maintain a consistent sleep and wake schedule",
                    "Create a relaxing pre-bed routine",
                    "Limit caffeine after 2 PM",
                    "Keep your bedroom dark and cool",
                ]
            )
        }
    }

    private func generateMilestones(for goal: UserGoal) -> [Milestone] {
        let fractions = [0.25, 0.5, 0.75, 1.0]
        return fractions.map { fraction in
            let pct = Int(fraction * 100)
            if goal.category.isDecreasing {
                let value = goal.startingValue - (goal.totalDistance * fraction)
                return Milestone(title: "Reach \(Int(value)) \(goal.unit) (\(pct)%)", targetValue: value)
            } else {
                let value = goal.startingValue + (goal.totalDistance * fraction)
                return Milestone(title: "Reach \(Int(value)) \(goal.unit) (\(pct)%)", targetValue: value)
            }
        }
    }

    private func triggerCelebration(_ message: String) {
        celebrationMessage = message
        showCelebration = true
        FeedbackManager.success()
    }

    func triggerPlanUpdated(_ message: String) {
        planUpdatedMessage = message
        showPlanUpdatedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showPlanUpdatedToast = false
        }
    }

    private func checkAndUnlockRewards() {
        for i in rewardProgress.rewards.indices {
            if !rewardProgress.rewards[i].isUnlocked && rewardProgress.totalPoints >= rewardProgress.rewards[i].pointsRequired {
                rewardProgress.rewards[i].isUnlocked = true
                rewardProgress.rewards[i].unlockedDate = Date()
            }
        }
    }

    private func unlockReward(category: Reward.RewardCategory) {
        if let index = rewardProgress.rewards.firstIndex(where: { $0.category == category && !$0.isUnlocked }) {
            rewardProgress.rewards[index].isUnlocked = true
            rewardProgress.rewards[index].unlockedDate = Date()
        }
    }

    static func defaultRewards() -> [Reward] {
        [
            Reward(title: "First Steps", description: "Set your first fitness goal", icon: "star.fill", pointsRequired: 0, isUnlocked: false, category: .milestone),
            Reward(title: "Getting Started", description: "Complete your first workout", icon: "flame.fill", pointsRequired: 15, category: .milestone),
            Reward(title: "On a Roll", description: "3-day workout streak", icon: "bolt.fill", pointsRequired: 45, category: .streak),
            Reward(title: "Quarter Way", description: "Reach 25% of any goal", icon: "flag.fill", pointsRequired: 75, category: .milestone),
            Reward(title: "Consistency King", description: "7-day workout streak", icon: "crown.fill", pointsRequired: 105, category: .streak),
            Reward(title: "Halfway Hero", description: "Reach 50% of any goal", icon: "medal.fill", pointsRequired: 150, category: .milestone),
            Reward(title: "Goal Crusher", description: "Complete your first goal", icon: "trophy.fill", pointsRequired: 200, category: .goalComplete),
            Reward(title: "Iron Will", description: "14-day workout streak", icon: "shield.fill", pointsRequired: 300, category: .streak),
            Reward(title: "Legend", description: "Reach Level 5", icon: "sparkles", pointsRequired: 500, category: .consistency),
        ]
    }

    // MARK: - Persistence

    private func saveData() {
        if let encoded = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(encoded, forKey: "savedGoals")
        }
        if let streakEncoded = try? JSONEncoder().encode(streakData) {
            UserDefaults.standard.set(streakEncoded, forKey: "streakData")
        }
        if let checkInEncoded = try? JSONEncoder().encode(checkInHistory) {
            UserDefaults.standard.set(checkInEncoded, forKey: "checkInHistory")
        }
        if let integrationEncoded = try? JSONEncoder().encode(integrationStatus) {
            UserDefaults.standard.set(integrationEncoded, forKey: "integrationStatus")
        }
        if let manualEncoded = try? JSONEncoder().encode(manualStats) {
            UserDefaults.standard.set(manualEncoded, forKey: "manualStats")
        }
        if let foodEncoded = try? JSONEncoder().encode(foodLog) {
            UserDefaults.standard.set(foodEncoded, forKey: "foodLog")
        }
        if let mealsEncoded = try? JSONEncoder().encode(Array(checkedMeals)) {
            UserDefaults.standard.set(mealsEncoded, forKey: "checkedMeals")
        }
        UserDefaults.standard.set(todayWaterOz, forKey: "todayWaterOz")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "waterDate")
        if let historyEncoded = try? JSONEncoder().encode(workoutHistory) {
            UserDefaults.standard.set(historyEncoded, forKey: "workoutHistory")
        }

        syncToSupabase()
    }

    private func syncToSupabase() {
        guard !userId.isEmpty else { return }
        let uid = userId
        let currentGoals = goals
        let currentStreak = streakData
        let currentStats = manualStats
        let currentFoodLog = foodLog
        let currentMeals = checkedMeals

        Task.detached {
            do {
                for goal in currentGoals {
                    try await SupabaseService.upsertGoal(goal, userId: uid)
                }
                try await SupabaseService.upsertStreak(currentStreak, userId: uid)
                try await SupabaseService.upsertManualStats(currentStats, userId: uid)
                try await SupabaseService.upsertCheckedMeals(currentMeals, userId: uid)
            } catch {
                print("Supabase sync error: \(error)")
            }
        }
    }

    func loadFromSupabase(userId: String) {
        self.userId = userId
        Task {
            do {
                let remoteGoals = try await SupabaseService.fetchGoals(userId: userId)
                if !remoteGoals.isEmpty {
                    await MainActor.run {
                        self.goals = remoteGoals
                        if !self.goals.isEmpty { self.generateTrainingPlan() }
                    }
                }

                let remoteCheckIns = try await SupabaseService.fetchCheckIns(userId: userId)
                if !remoteCheckIns.isEmpty {
                    await MainActor.run {
                        self.checkInHistory = remoteCheckIns
                        let today = Calendar.current.startOfDay(for: Date())
                        self.todayCheckIn = remoteCheckIns.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
                    }
                }

                let remoteFoodLog = try await SupabaseService.fetchFoodLog(userId: userId)
                if !remoteFoodLog.isEmpty {
                    await MainActor.run { self.foodLog = remoteFoodLog }
                }

                if let remoteStreak = try await SupabaseService.fetchStreak(userId: userId) {
                    await MainActor.run {
                        self.streakData = remoteStreak
                        self.rewardProgress.currentStreak = remoteStreak.currentStreak
                        self.rewardProgress.longestStreak = remoteStreak.longestStreak
                    }
                }

                if let remoteStats = try await SupabaseService.fetchManualStats(userId: userId) {
                    await MainActor.run { self.manualStats = remoteStats }
                }

                let remoteMeals = try await SupabaseService.fetchCheckedMeals(userId: userId)
                if !remoteMeals.isEmpty {
                    await MainActor.run { self.checkedMeals = remoteMeals }
                }
            } catch {
                print("Supabase load error: \(error)")
            }
        }
    }

    private func loadSavedData() {
        if let data = UserDefaults.standard.data(forKey: "savedGoals"),
           let decoded = try? JSONDecoder().decode([UserGoal].self, from: data) {
            goals = decoded
            if !goals.isEmpty { generateTrainingPlan() }
        }
        if let data = UserDefaults.standard.data(forKey: "streakData"),
           let decoded = try? JSONDecoder().decode(StreakData.self, from: data) {
            streakData = decoded
            rewardProgress.currentStreak = streakData.currentStreak
            rewardProgress.longestStreak = streakData.longestStreak
        }
        if let data = UserDefaults.standard.data(forKey: "checkInHistory"),
           let decoded = try? JSONDecoder().decode([DailyCheckIn].self, from: data) {
            checkInHistory = decoded
            let today = Calendar.current.startOfDay(for: Date())
            todayCheckIn = decoded.last { Calendar.current.isDate($0.date, inSameDayAs: today) }
        }
        if let data = UserDefaults.standard.data(forKey: "integrationStatus"),
           let decoded = try? JSONDecoder().decode(HealthIntegrationStatus.self, from: data) {
            integrationStatus = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "manualStats"),
           let decoded = try? JSONDecoder().decode(ManualHealthStats.self, from: data) {
            manualStats = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "foodLog"),
           let decoded = try? JSONDecoder().decode([FoodLogEntry].self, from: data) {
            foodLog = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "checkedMeals"),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            checkedMeals = Set(decoded)
        }
        if let data = UserDefaults.standard.data(forKey: "workoutHistory"),
           let decoded = try? JSONDecoder().decode([WorkoutHistoryEntry].self, from: data) {
            workoutHistory = decoded
        }

        // Load water — reset if it's a new day
        let waterTimestamp = UserDefaults.standard.double(forKey: "waterDate")
        if waterTimestamp > 0 {
            let waterDate = Date(timeIntervalSince1970: waterTimestamp)
            if Calendar.current.isDateInToday(waterDate) {
                todayWaterOz = UserDefaults.standard.integer(forKey: "todayWaterOz")
            } else {
                todayWaterOz = 0
            }
        }
    }
}
