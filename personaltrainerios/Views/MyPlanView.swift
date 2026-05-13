import SwiftUI

struct MyPlanView: View {
    var viewModel: AppViewModel
    var subscriptionManager: SubscriptionManager
    @State private var selectedSegment: PlanSegment = .workouts
    @State private var showAddFood = false
    @State private var showMealPlan = false
    @State private var showFoodLog = false
    @State private var showHistory = false

    enum PlanSegment: String, CaseIterable {
        case workouts = "Workouts"
        case nutrition = "Nutrition"
        case sleep = "Sleep"
    }

    private func applyRoute(_ route: String?) {
        guard let route else { return }
        switch route {
        case "workouts": selectedSegment = .workouts
        case "nutrition": selectedSegment = .nutrition
        case "sleep": selectedSegment = .sleep
        default: break
        }
        // Clear so the same route doesn't re-trigger on every recompose
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            viewModel.planSegmentRoute = nil
        }
    }

    var body: some View {
        NavigationStack {
            if viewModel.trainingPlan != nil {
                VStack(spacing: 0) {
                    Picker("Section", selection: $selectedSegment) {
                        ForEach(PlanSegment.allCases, id: \.self) { segment in
                            Text(segment.rawValue).tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    ScrollView {
                        VStack(spacing: 16) {
                            switch selectedSegment {
                            case .workouts:
                                workoutsContent
                            case .nutrition:
                                nutritionContent
                            case .sleep:
                                sleepContent
                            }
                        }
                        .padding()
                    }
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("My Plan")
                .sheet(isPresented: $showAddFood) {
                    AddFoodSheet(viewModel: viewModel)
                }
                .sheet(isPresented: $showHistory) {
                    WorkoutHistoryView(viewModel: viewModel)
                }
                .onChange(of: viewModel.planSegmentRoute) { _, route in
                    applyRoute(route)
                }
                .task {
                    applyRoute(viewModel.planSegmentRoute)
                }
            } else {
                emptyState
                    .navigationTitle("My Plan")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.clipboard.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            Text("No Plan Yet")
                .font(.title2)
                .fontWeight(.bold)
            Text("Set a goal and we'll build your personalized workout, nutrition, and sleep plan.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
        }
        .padding(40)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Workouts

    private var workoutsContent: some View {
        Group {
            if let plan = viewModel.trainingPlan {
                weekHeader(plan)
                historyButton
                ForEach(plan.workouts) { workout in
                    WorkoutDetailCard(workout: workout, forceExpanded: viewModel.expandWorkoutId == workout.id) {
                        viewModel.completeWorkout(workout.id)
                    }
                }
                .onAppear {
                    // Clear after navigating so it doesn't stay expanded on next visit
                    if viewModel.expandWorkoutId != nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            viewModel.expandWorkoutId = nil
                        }
                    }
                }
            }
        }
    }

    private var historyButton: some View {
        let isLocked = !subscriptionManager.hasFullAccess
        return Button {
            FeedbackManager.light()
            if isLocked {
                viewModel.activeSheet = .paywall
            } else {
                showHistory = true
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isLocked ? "lock.fill" : "clock.arrow.circlepath")
                    .foregroundStyle(isLocked ? .purple : .blue)
                    .font(.title3)
                    .frame(width: 28, height: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Workout History")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    if isLocked {
                        Text("Subscribe to view your full workout history")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if viewModel.workoutHistory.isEmpty {
                        Text("Your completed workouts will appear here")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(viewModel.workoutHistory.count) completed workouts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isLocked ? "Workout History, locked. Tap to subscribe." : "Workout History, \(viewModel.workoutHistory.count) completed workouts")
    }

    private func weekHeader(_ plan: TrainingPlan) -> some View {
        let completed = plan.workouts.filter(\.isCompleted).count
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Week \(plan.weekNumber)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(CoachCopy.weekProgress(completed: completed, total: plan.workouts.count))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            CircularProgress(
                progress: Double(completed) / Double(max(plan.workouts.count, 1)),
                color: .blue
            )
            .frame(width: 50, height: 50)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Nutrition

    private var nutritionContent: some View {
        Group {
            if let plan = viewModel.trainingPlan?.nutritionPlan {
                calorieAndMacroCard(plan)
                hydrationCard(plan)
                mealsSection(plan)
                if !viewModel.foodLog.isEmpty {
                    foodLogSection
                }
            }
        }
    }

    private func calorieAndMacroCard(_ plan: NutritionPlan) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Calories")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(viewModel.todayLoggedCalories)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("/ \(plan.dailyCalories)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                let remaining = max(plan.dailyCalories - viewModel.todayLoggedCalories, 0)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(remaining)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(remaining > 0 ? .orange : .green)
                    Text("remaining")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            ProgressView(value: min(Double(viewModel.todayLoggedCalories) / Double(max(plan.dailyCalories, 1)), 1.0))
                .tint(viewModel.todayLoggedCalories <= plan.dailyCalories ? .blue : .red)

            Divider()

            HStack(spacing: 0) {
                MacroRing(label: "Protein", grams: plan.proteinGrams, color: .red, total: plan.dailyCalories)
                    .frame(maxWidth: .infinity)
                MacroRing(label: "Carbs", grams: plan.carbsGrams, color: .blue, total: plan.dailyCalories)
                    .frame(maxWidth: .infinity)
                MacroRing(label: "Fat", grams: plan.fatGrams, color: .yellow, total: plan.dailyCalories)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func hydrationCard(_ plan: NutritionPlan) -> some View {
        let glasses = viewModel.todayWaterOz / 8
        let targetGlasses = plan.hydrationOz / 8
        let progress = min(Double(viewModel.todayWaterOz) / Double(max(plan.hydrationOz, 1)), 1.0)

        return VStack(spacing: 12) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.title3)
                    .foregroundStyle(.cyan)
                VStack(alignment: .leading, spacing: 2) {
                    Text(CoachCopy.hydrationEncouragement(glasses: glasses, target: targetGlasses))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("\(viewModel.todayWaterOz) / \(plan.hydrationOz) oz")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(glasses)/\(targetGlasses)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(progress >= 1.0 ? .green : .cyan)
            }

            ProgressView(value: progress)
                .tint(progress >= 1.0 ? .green : .cyan)

            HStack(spacing: 12) {
                Button {
                    viewModel.removeWater(8)
                } label: {
                    Image(systemName: "minus")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemGray5), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(viewModel.todayWaterOz == 0)
                .accessibilityLabel("Remove 8 ounces of water")

                // Glass icons
                HStack(spacing: 4) {
                    ForEach(0..<min(targetGlasses, 12), id: \.self) { i in
                        Image(systemName: i < glasses ? "drop.fill" : "drop")
                            .font(.caption2)
                            .foregroundStyle(i < glasses ? .cyan : Color(.systemGray4))
                    }
                }

                Button {
                    viewModel.addWater(8)
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.cyan, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add 8 ounces of water")
            }
            .accessibilityElement(children: .contain)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func mealsSection(_ plan: NutritionPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                FeedbackManager.light()
                withAnimation { showMealPlan.toggle() }
            } label: {
                HStack {
                    Text("Meal Plan")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    let checked = plan.meals.filter { viewModel.checkedMeals.contains($0.id.uuidString) }.count
                    Text("\(checked)/\(plan.meals.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(showMealPlan ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if showMealPlan {
                ForEach(plan.meals) { meal in
                    MealRow(meal: meal, isChecked: viewModel.checkedMeals.contains(meal.id.uuidString)) {
                        viewModel.toggleMealChecked(meal.id.uuidString)
                    }
                }
            }
        }
    }

    private var foodLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    FeedbackManager.light()
                    withAnimation { showFoodLog.toggle() }
                } label: {
                    HStack {
                        Text("Food Log")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if !viewModel.todayFoodLog.isEmpty {
                            Text("(\(viewModel.todayFoodLog.count))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(showFoodLog ? 90 : 0))
                    }
                }
                .buttonStyle(.plain)
                Spacer()
                Button {
                    showAddFood = true
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            if showFoodLog {

            if viewModel.todayFoodLog.isEmpty {
                HStack {
                    Image(systemName: "fork.knife.circle")
                        .foregroundStyle(.secondary)
                    Text("No food logged today. Tap + to track what you eat.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(viewModel.todayFoodLog) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            HStack(spacing: 8) {
                                if let meal = entry.mealName {
                                    Text(meal)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(.systemGray5), in: Capsule())
                                }
                                Text(entry.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if entry.calories > 0 {
                            Text("\(entry.calories) cal")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.orange)
                        }
                        Button {
                            viewModel.removeFoodLogEntry(entry.id)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color(.systemGray3))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }

                HStack {
                    Text("Total logged")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(viewModel.todayLoggedCalories) cal")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 4)
            }
            }
        }
    }

    // MARK: - Sleep

    private var sleepContent: some View {
        Group {
            if let rec = viewModel.trainingPlan?.sleepRecommendation {
                VStack(alignment: .leading, spacing: 16) {
                    // Schedule card
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Image(systemName: "moon.fill")
                                .font(.title2)
                                .foregroundStyle(.indigo)
                            Text(rec.bedtime)
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Bedtime")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        Image(systemName: "arrow.right")
                            .foregroundStyle(.secondary)

                        VStack(spacing: 4) {
                            Image(systemName: "sun.horizon.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                            Text(rec.wakeTime)
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Wake Up")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            Text(String(format: "%.1f", rec.targetHours))
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Hours")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                    // Actual sleep from Health (if available)
                    if let snapshot = viewModel.effectiveSnapshot, snapshot.sleepHours > 0 {
                        HStack {
                            Image(systemName: "bed.double.fill")
                                .foregroundStyle(.indigo)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Last Night")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(String(format: "%.1f", snapshot.sleepHours))
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Text("hours")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            let delta = snapshot.sleepHours - rec.targetHours
                            if abs(delta) > 0.1 {
                                Text(delta > 0 ? "+\(String(format: "%.1f", delta))h" : "\(String(format: "%.1f", delta))h")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(delta >= 0 ? .green : .orange)
                            } else {
                                Text("On target")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }

                    // Tips
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sleep Tips")
                            .font(.headline)
                        ForEach(rec.tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.caption)
                                    .padding(.top, 2)
                                Text(tip)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }
}
