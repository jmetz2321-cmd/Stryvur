import SwiftUI

struct NutritionView: View {
    var viewModel: AppViewModel
    @State private var showAddFood = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let plan = viewModel.trainingPlan?.nutritionPlan {
                        calorieAndMacroCard(plan)
                        hydrationCard(plan)
                        mealsSection(plan)
                        foodLogSection
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Nutrition")
            .sheet(isPresented: $showAddFood) {
                AddFoodSheet(viewModel: viewModel)
            }
        }
    }

    // MARK: - Combined Calorie + Macro Card

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

    // MARK: - Hydration

    private func hydrationCard(_ plan: NutritionPlan) -> some View {
        HStack {
            Image(systemName: "drop.fill")
                .font(.title3)
                .foregroundStyle(.cyan)
            VStack(alignment: .leading, spacing: 2) {
                Text("Hydration")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(plan.hydrationOz) oz \u{2022} \(plan.hydrationOz / 8) glasses")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Meals

    private func mealsSection(_ plan: NutritionPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Meal Plan")
                    .font(.headline)
                Spacer()
                let checked = plan.meals.filter { viewModel.checkedMeals.contains($0.id.uuidString) }.count
                Text("\(checked)/\(plan.meals.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            ForEach(plan.meals) { meal in
                MealRow(meal: meal, isChecked: viewModel.checkedMeals.contains(meal.id.uuidString)) {
                    viewModel.toggleMealChecked(meal.id.uuidString)
                }
            }
        }
    }

    // MARK: - Food Log

    private var foodLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Food Log")
                    .font(.headline)
                Spacer()
                Button {
                    showAddFood = true
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

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

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            Text("No Nutrition Plan Yet")
                .font(.title2)
                .fontWeight(.bold)
            Text("Set a goal to receive a personalized nutrition plan.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(40)
    }
}

// MARK: - Meal Row (expandable)

struct MealRow: View {
    let meal: Meal
    let isChecked: Bool
    let onToggle: () -> Void
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isChecked ? .green : Color(.systemGray3))
                }
                .buttonStyle(.plain)

                Button { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(meal.name)
                                .fontWeight(.semibold)
                                .strikethrough(isChecked)
                                .foregroundStyle(isChecked ? .secondary : .primary)
                            Text(meal.time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(meal.calories) cal")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.orange)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding()

            if isExpanded && !isChecked {
                Divider()
                    .padding(.horizontal)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(meal.foods, id: \.self) { food in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(.secondary)
                                .frame(width: 4, height: 4)
                            Text(food)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
                .padding(.leading, 44)
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Macro Ring

struct MacroRing: View {
    let label: String
    let grams: Int
    let color: Color
    let total: Int

    private var calories: Int {
        switch label {
        case "Fat": return grams * 9
        default: return grams * 4
        }
    }

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(calories) / Double(total)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: percentage)
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(percentage * 100))%")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
            .frame(width: 50, height: 50)
            Text("\(grams)g")
                .font(.caption)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Add Food Sheet

struct AddFoodSheet: View {
    var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var foodName = ""
    @State private var calories = ""
    @State private var selectedMeal = "Snack"

    private let mealOptions = ["Breakfast", "Lunch", "Dinner", "Snack", "Pre-Workout", "Post-Workout", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                Section("What did you eat?") {
                    TextField("Food name (e.g. Grilled chicken)", text: $foodName)
                    TextField("Calories (optional)", text: $calories)
                        .keyboardType(.numberPad)
                }

                Section("Meal") {
                    Picker("Meal", selection: $selectedMeal) {
                        ForEach(mealOptions, id: \.self) { meal in
                            Text(meal).tag(meal)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    Button {
                        let entry = FoodLogEntry(
                            name: foodName,
                            calories: Int(calories) ?? 0,
                            mealName: selectedMeal
                        )
                        viewModel.addFoodLogEntry(entry)
                        dismiss()
                    } label: {
                        Text("Log Food")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(foodName.isEmpty)
                }
            }
            .navigationTitle("Log Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
