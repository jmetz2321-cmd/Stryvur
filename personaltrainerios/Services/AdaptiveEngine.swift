import Foundation

struct AdaptiveEngine {

    // MARK: - Workout Adaptation (Today's Focus)

    static func adaptWorkout(_ workout: Workout, checkIn: DailyCheckIn?, healthSnapshot: HealthSnapshot?) -> Workout {
        var adapted = workout
        guard let checkIn else {
            // Even without check-in, adapt based on health data
            if let snapshot = healthSnapshot {
                adapted = adaptForHealth(adapted, snapshot: snapshot)
            }
            return adapted
        }

        // Severe: swap to full recovery
        if checkIn.shouldSwapToRecovery {
            adapted.name = "Recovery: \(adapted.name)"
            adapted.intensity = .low
            adapted.durationMinutes = max(20, adapted.durationMinutes - 20)
            adapted.exercises = adapted.exercises.map { exercise in
                var e = exercise
                e.sets = max(1, e.sets - 2)
                e.restSeconds = e.restSeconds + 45
                e.notes = (e.notes ?? "") + " (recovery pace)"
                return e
            }
            // Add recovery exercises
            adapted.exercises.append(Exercise(name: "Foam Rolling", sets: 1, reps: "10 min", restSeconds: 0, notes: "Focus on sore areas"))
            adapted.exercises.append(Exercise(name: "Deep Stretching", sets: 1, reps: "10 min", restSeconds: 0, notes: "Hold each stretch 30-60s"))
        }
        // Moderate: reduce intensity
        else if checkIn.shouldReduceIntensity {
            if adapted.intensity == .high { adapted.intensity = .moderate }
            adapted.durationMinutes = max(20, adapted.durationMinutes - 10)
            adapted.exercises = adapted.exercises.map { exercise in
                var e = exercise
                e.restSeconds = e.restSeconds + 20
                if checkIn.sorenessLevel >= 4 {
                    e.sets = max(1, e.sets - 1)
                    e.notes = (e.notes ?? "") + " (reduced for soreness)"
                }
                return e
            }
        }
        // Feeling great: push harder
        else if checkIn.mood == .great && checkIn.energyLevel >= 4 && checkIn.sorenessLevel <= 2 {
            if adapted.intensity == .moderate { adapted.intensity = .high }
            adapted.durationMinutes += 10
            adapted.exercises = adapted.exercises.map { exercise in
                var e = exercise
                e.sets += 1
                e.restSeconds = max(15, e.restSeconds - 15)
                e.notes = (e.notes ?? "") + " (push day!)"
                return e
            }
        }

        // Layer on health data adjustments
        if let snapshot = healthSnapshot {
            adapted = adaptForHealth(adapted, snapshot: snapshot)
        }

        // Soreness-specific exercise swaps
        if checkIn.sorenessLevel >= 3 {
            adapted = addWarmupAndCooldown(adapted)
        }

        return adapted
    }

    private static func adaptForHealth(_ workout: Workout, snapshot: HealthSnapshot) -> Workout {
        var adapted = workout

        // Very poor sleep — force lighter session
        if snapshot.sleepHours > 0 && snapshot.sleepHours < 5 {
            adapted.intensity = .low
            adapted.durationMinutes = max(20, adapted.durationMinutes - 20)
            adapted.exercises = adapted.exercises.map { e in
                var ex = e
                ex.sets = max(1, ex.sets - 1)
                ex.restSeconds += 30
                return ex
            }
        } else if snapshot.sleepHours >= 5 && snapshot.sleepHours < 6 {
            if adapted.intensity == .high { adapted.intensity = .moderate }
            adapted.durationMinutes = max(20, adapted.durationMinutes - 10)
        }

        // Elevated resting HR = body under stress
        if snapshot.restingHeartRate > 85 {
            adapted.intensity = .low
            adapted.durationMinutes = max(20, adapted.durationMinutes - 15)
        } else if snapshot.restingHeartRate > 75 {
            if adapted.intensity == .high { adapted.intensity = .moderate }
        }

        // Very active day already (high steps) — can reduce cardio
        if snapshot.activeMinutes > 60 && snapshot.steps > 12000 {
            adapted.durationMinutes = max(20, adapted.durationMinutes - 10)
        }

        return adapted
    }

    private static func addWarmupAndCooldown(_ workout: Workout) -> Workout {
        var adapted = workout
        let hasWarmup = adapted.exercises.contains { $0.name.lowercased().contains("warm") }
        if !hasWarmup {
            adapted.exercises.insert(
                Exercise(name: "Dynamic Warmup", sets: 1, reps: "5 min", restSeconds: 0, notes: "Arm circles, leg swings, hip openers"),
                at: 0
            )
        }
        let hasCooldown = adapted.exercises.contains { $0.name.lowercased().contains("stretch") || $0.name.lowercased().contains("cool") }
        if !hasCooldown {
            adapted.exercises.append(
                Exercise(name: "Cooldown Stretch", sets: 1, reps: "5 min", restSeconds: 0, notes: "Focus on worked muscle groups")
            )
        }
        return adapted
    }

    // MARK: - Weekly Plan Adaptation

    static func adaptWeeklyPlan(_ workouts: [Workout], checkInHistory: [DailyCheckIn], healthSnapshot: HealthSnapshot?) -> [Workout] {
        var adapted = workouts

        // Analyze recent check-in trends (last 7 days)
        let recentCheckIns = checkInHistory.suffix(7)
        let avgEnergy = recentCheckIns.isEmpty ? 3.0 : Double(recentCheckIns.reduce(0) { $0 + $1.energyLevel }) / Double(recentCheckIns.count)
        let avgSoreness = recentCheckIns.isEmpty ? 1.0 : Double(recentCheckIns.reduce(0) { $0 + $1.sorenessLevel }) / Double(recentCheckIns.count)
        let tiredDays = recentCheckIns.filter { $0.mood == .tired || $0.mood == .awful }.count

        // Chronically tired pattern — reduce overall weekly volume
        if avgEnergy < 2.5 || tiredDays >= 3 {
            adapted = adapted.map { workout in
                guard !workout.isCompleted else { return workout }
                var w = workout
                if w.intensity == .high { w.intensity = .moderate }
                w.durationMinutes = max(25, w.durationMinutes - 10)
                w.exercises = w.exercises.map { e in
                    var ex = e
                    ex.sets = max(1, ex.sets - 1)
                    return ex
                }
                return w
            }
        }
        // Consistently strong — increase weekly volume
        else if avgEnergy >= 4.0 && avgSoreness < 2.0 && tiredDays == 0 {
            adapted = adapted.map { workout in
                guard !workout.isCompleted else { return workout }
                var w = workout
                if w.intensity == .moderate { w.intensity = .high }
                w.exercises = w.exercises.map { e in
                    var ex = e
                    ex.sets += 1
                    return ex
                }
                return w
            }
        }

        // High chronic soreness — add recovery day swap
        if avgSoreness >= 3.5 {
            adapted = adapted.map { workout in
                guard !workout.isCompleted else { return workout }
                if workout.intensity == .high {
                    var w = workout
                    w.intensity = .moderate
                    w.exercises = w.exercises.map { e in
                        var ex = e
                        ex.restSeconds += 15
                        return ex
                    }
                    return w
                }
                return workout
            }
        }

        // Poor sleep pattern — adjust all remaining workouts
        if let snapshot = healthSnapshot, snapshot.sleepHours > 0 && snapshot.sleepHours < 6 {
            adapted = adapted.map { workout in
                guard !workout.isCompleted else { return workout }
                var w = workout
                w.durationMinutes = max(20, w.durationMinutes - 5)
                return w
            }
        }

        return adapted
    }

    // MARK: - Nutrition Adaptation

    static func adaptNutrition(_ plan: NutritionPlan, checkIn: DailyCheckIn?, healthSnapshot: HealthSnapshot?, goal: UserGoal?) -> NutritionPlan {
        var adapted = plan

        // Adapt based on check-in
        if let checkIn {
            // Poor sleep — add carbs for energy, increase hydration
            if checkIn.sleepRating <= 2 {
                adapted.carbsGrams += 30
                adapted.hydrationOz = max(adapted.hydrationOz, 88)
                adapted.dailyCalories = recalcCalories(adapted)
            }

            // High soreness — increase protein for recovery
            if checkIn.sorenessLevel >= 3 {
                adapted.proteinGrams += 20
                adapted.dailyCalories = recalcCalories(adapted)
                // Swap meal foods for recovery-focused options
                adapted.meals = adapted.meals.map { meal in
                    if meal.name == "Snack" || meal.name == "Evening Snack" || meal.name == "Before Bed" {
                        var m = meal
                        m.foods = ["Protein shake", "Tart cherry juice", "Almonds"]
                        m.calories = 250
                        return m
                    }
                    return meal
                }
            }

            // Low energy — boost calories slightly
            if checkIn.energyLevel <= 2 {
                adapted.dailyCalories += 150
                adapted.carbsGrams += 20
            }

            // Feeling great — can tighten deficit for weight loss
            if checkIn.mood == .great && checkIn.energyLevel >= 4 {
                if let goal, goal.category == .weightLoss {
                    adapted.dailyCalories = max(1400, adapted.dailyCalories - 100)
                }
            }
        }

        // Adapt based on health snapshot
        if let snapshot = healthSnapshot {
            // Poor sleep from Apple Health
            if snapshot.sleepHours > 0 && snapshot.sleepHours < 5 {
                adapted.carbsGrams += 40
                adapted.hydrationOz = max(adapted.hydrationOz, 96)
                adapted.dailyCalories = recalcCalories(adapted)
            } else if snapshot.sleepHours >= 5 && snapshot.sleepHours < 6 {
                adapted.carbsGrams += 20
                adapted.hydrationOz = max(adapted.hydrationOz, 88)
                adapted.dailyCalories = recalcCalories(adapted)
            }

            // Elevated HR — stress response, boost hydration and magnesium-rich foods
            if snapshot.restingHeartRate > 80 {
                adapted.hydrationOz = max(adapted.hydrationOz, 90)
            }

            // Very active day — increase calories to fuel activity
            if snapshot.caloriesBurned > 500 {
                let extraCals = Int((snapshot.caloriesBurned - 300) * 0.5)
                adapted.dailyCalories += extraCals
                adapted.carbsGrams += extraCals / 8
            }

            // Weight-based protein and calorie calculation
            if let weight = snapshot.weight, let goal {
                switch goal.category {
                case .muscleGain:
                    let targetProtein = Int(weight * 1.0)
                    adapted.proteinGrams = max(adapted.proteinGrams, targetProtein)
                    let targetCals = Int(weight * 18)
                    adapted.dailyCalories = max(adapted.dailyCalories, targetCals)
                case .weightLoss:
                    let targetProtein = Int(weight * 0.8)
                    adapted.proteinGrams = max(adapted.proteinGrams, targetProtein)
                    let targetCals = Int(weight * 12)
                    adapted.dailyCalories = max(1400, min(targetCals, adapted.dailyCalories))
                default:
                    let targetProtein = Int(weight * 0.7)
                    adapted.proteinGrams = max(adapted.proteinGrams, targetProtein)
                }
                adapted.dailyCalories = recalcCalories(adapted)
            }
        }

        return adapted
    }

    private static func recalcCalories(_ plan: NutritionPlan) -> Int {
        return plan.proteinGrams * 4 + plan.carbsGrams * 4 + plan.fatGrams * 9
    }

    // MARK: - Sleep Adaptation

    static func adaptSleep(_ rec: SleepRecommendation, checkIn: DailyCheckIn?, healthSnapshot: HealthSnapshot?) -> SleepRecommendation {
        var adapted = rec

        if let checkIn {
            if checkIn.sleepRating <= 2 || checkIn.mood == .tired || checkIn.mood == .awful {
                adapted.targetHours = max(adapted.targetHours, 9.0)
                adapted.bedtime = "9:30 PM"
                adapted.tips.insert("You reported poor sleep — prioritize an earlier bedtime tonight", at: 0)
            }

            if checkIn.sorenessLevel >= 4 {
                adapted.targetHours = max(adapted.targetHours, 8.5)
                adapted.tips.insert("High soreness — extra sleep boosts muscle recovery and growth hormone", at: 0)
            }
        }

        if let snapshot = healthSnapshot {
            if snapshot.sleepHours > 0 && snapshot.sleepHours < 6 {
                adapted.targetHours = max(adapted.targetHours, 9.0)
                adapted.bedtime = "9:30 PM"
                adapted.tips.insert("You slept \(String(format: "%.1f", snapshot.sleepHours))h last night — aim for more tonight", at: 0)
            }

            if snapshot.restingHeartRate > 80 {
                adapted.tips.insert("Elevated resting HR — deep breathing before bed can help lower stress", at: 0)
            }
        }

        // Cap tips at 4 to avoid clutter
        if adapted.tips.count > 4 {
            adapted.tips = Array(adapted.tips.prefix(4))
        }

        return adapted
    }

    // MARK: - Insights

    static func generateInsights(checkIn: DailyCheckIn?, healthSnapshot: HealthSnapshot?, functionVitals: FunctionHealthVitals?, streakData: StreakData) -> [AdaptiveInsight] {
        var insights: [AdaptiveInsight] = []

        if let checkIn {
            insights.append(contentsOf: checkInInsights(checkIn))
        }
        if let snapshot = healthSnapshot {
            insights.append(contentsOf: healthInsights(snapshot))
        }
        if let vitals = functionVitals {
            insights.append(contentsOf: biomarkerInsights(vitals))
        }
        insights.append(contentsOf: streakInsights(streakData))

        return insights
    }

    private static func checkInInsights(_ checkIn: DailyCheckIn) -> [AdaptiveInsight] {
        var insights: [AdaptiveInsight] = []

        if checkIn.shouldSwapToRecovery {
            insights.append(AdaptiveInsight(
                title: "Recovery Day Activated",
                message: "Your body needs rest. We've replaced today's workout with a recovery session — stretching, foam rolling, and light movement.",
                icon: "bed.double.fill",
                color: "indigo",
                actionLabel: "View Adjusted Plan",
                source: .checkIn
            ))
        } else if checkIn.shouldReduceIntensity {
            insights.append(AdaptiveInsight(
                title: "Intensity Adjusted",
                message: "Based on your energy and soreness, we've reduced today's sets and added extra rest between exercises.",
                icon: "arrow.down.circle.fill",
                color: "orange",
                source: .checkIn
            ))
        } else if checkIn.mood == .great && checkIn.energyLevel >= 4 {
            insights.append(AdaptiveInsight(
                title: "Push Day!",
                message: "You're feeling strong — we've added an extra set per exercise and shortened rest. Time to make gains!",
                icon: "bolt.fill",
                color: "green",
                source: .checkIn
            ))
        }

        if checkIn.sorenessLevel >= 3 {
            insights.append(AdaptiveInsight(
                title: "Recovery Nutrition Activated",
                message: "High soreness detected. We've increased protein by 20g and added recovery snacks to your meal plan.",
                icon: "figure.flexibility",
                color: "purple",
                source: .checkIn
            ))
        }

        if checkIn.sleepRating <= 2 {
            insights.append(AdaptiveInsight(
                title: "Sleep Recovery Mode",
                message: "Poor sleep reported. Added extra carbs for energy and moved bedtime earlier tonight.",
                icon: "moon.zzz.fill",
                color: "indigo",
                source: .checkIn
            ))
        }

        return insights
    }

    private static func healthInsights(_ snapshot: HealthSnapshot) -> [AdaptiveInsight] {
        var insights: [AdaptiveInsight] = []

        if snapshot.sleepHours > 0 && snapshot.sleepHours < 5 {
            insights.append(AdaptiveInsight(
                title: "Very Low Sleep",
                message: "Only \(String(format: "%.1f", snapshot.sleepHours))h of sleep. Today's workout is set to recovery mode and we've boosted carbs for energy.",
                icon: "moon.zzz.fill",
                color: "red",
                source: .appleHealth
            ))
        } else if snapshot.sleepHours >= 5 && snapshot.sleepHours < 6 {
            insights.append(AdaptiveInsight(
                title: "Low Sleep",
                message: "\(String(format: "%.1f", snapshot.sleepHours))h of sleep. Intensity reduced and extra hydration added to your plan.",
                icon: "moon.zzz.fill",
                color: "orange",
                source: .appleHealth
            ))
        } else if snapshot.sleepHours >= 8 {
            insights.append(AdaptiveInsight(
                title: "Great Sleep!",
                message: "\(String(format: "%.1f", snapshot.sleepHours))h of quality rest. Your body is primed for a strong workout today.",
                icon: "moon.stars.fill",
                color: "blue",
                source: .appleHealth
            ))
        }

        if snapshot.restingHeartRate > 85 {
            insights.append(AdaptiveInsight(
                title: "High Resting HR",
                message: "Resting HR of \(Int(snapshot.restingHeartRate)) bpm suggests stress or under-recovery. Today's session is lightened.",
                icon: "heart.fill",
                color: "red",
                source: .appleHealth
            ))
        } else if snapshot.restingHeartRate > 75 {
            insights.append(AdaptiveInsight(
                title: "Elevated Resting HR",
                message: "Resting HR at \(Int(snapshot.restingHeartRate)) bpm — slightly elevated. Keeping intensity moderate today.",
                icon: "heart.fill",
                color: "orange",
                source: .appleHealth
            ))
        }

        if snapshot.caloriesBurned > 500 {
            insights.append(AdaptiveInsight(
                title: "High Activity Day",
                message: "You've burned \(Int(snapshot.caloriesBurned)) active calories. We've increased today's calorie target to keep you fueled.",
                icon: "flame.fill",
                color: "orange",
                source: .appleHealth
            ))
        }

        if snapshot.steps > 12000 {
            insights.append(AdaptiveInsight(
                title: "Very Active!",
                message: "\(snapshot.steps.formatted()) steps today. Your workout has been shortened since you're already well-moved.",
                icon: "figure.walk",
                color: "green",
                source: .appleHealth
            ))
        }

        return insights
    }

    private static func biomarkerInsights(_ vitals: FunctionHealthVitals) -> [AdaptiveInsight] {
        var insights: [AdaptiveInsight] = []

        let flagged = vitals.biomarkers.filter { $0.status != .normal }
        if !flagged.isEmpty {
            let lowIron = flagged.first { $0.name.lowercased().contains("iron") || $0.name.lowercased().contains("ferritin") }
            if let iron = lowIron, iron.status == .low {
                insights.append(AdaptiveInsight(
                    title: "Low Iron Levels",
                    message: "Iron-rich foods have been prioritized in your meal plan. Consider consulting your doctor.",
                    icon: "drop.fill",
                    color: "red",
                    source: .functionHealth
                ))
            }

            let vitD = flagged.first { $0.name.lowercased().contains("vitamin d") }
            if let d = vitD, d.status == .low {
                insights.append(AdaptiveInsight(
                    title: "Low Vitamin D",
                    message: "Supports bone health and recovery. Consider supplementation and morning sunlight.",
                    icon: "sun.max.fill",
                    color: "yellow",
                    source: .functionHealth
                ))
            }

            let inflammation = flagged.first { $0.name.lowercased().contains("crp") || $0.name.lowercased().contains("inflammation") }
            if let inf = inflammation, inf.status == .high {
                insights.append(AdaptiveInsight(
                    title: "Elevated Inflammation",
                    message: "Anti-inflammatory foods and extra recovery are prioritized in your plan.",
                    icon: "exclamationmark.triangle.fill",
                    color: "orange",
                    source: .functionHealth
                ))
            }
        }

        return insights
    }

    private static func streakInsights(_ streak: StreakData) -> [AdaptiveInsight] {
        var insights: [AdaptiveInsight] = []

        if streak.streakIsAtRisk {
            insights.append(AdaptiveInsight(
                title: "Streak at Risk!",
                message: "Your \(streak.currentStreak)-day streak is about to break. Any activity today keeps it alive!",
                icon: "flame.fill",
                color: "orange",
                actionLabel: "Save Streak",
                source: .streak
            ))
        }

        if streak.currentStreak > 0 && streak.currentStreak % 7 == 0 {
            insights.append(AdaptiveInsight(
                title: "\(streak.currentStreak)-Day Streak!",
                message: "Incredible consistency! You've earned a streak freeze.",
                icon: "crown.fill",
                color: "yellow",
                source: .streak
            ))
        }

        return insights
    }
}
