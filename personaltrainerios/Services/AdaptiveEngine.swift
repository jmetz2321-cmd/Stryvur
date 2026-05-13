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
        let isWeightLoss = goal?.category == .weightLoss

        // Adapt based on check-in
        if let checkIn {
            // Poor sleep — bump hydration, small carb boost (but don't raise calories for weight loss)
            if checkIn.sleepRating <= 2 {
                adapted.hydrationOz = max(adapted.hydrationOz, 88)
                if !isWeightLoss {
                    adapted.carbsGrams += 30
                    adapted.dailyCalories = recalcCalories(adapted)
                }
            }

            // High soreness — increase protein for recovery (redistribute from carbs to keep cals stable)
            if checkIn.sorenessLevel >= 3 {
                adapted.proteinGrams += 20
                if isWeightLoss {
                    adapted.carbsGrams = max(100, adapted.carbsGrams - 20)
                }
                adapted.dailyCalories = recalcCalories(adapted)
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

            // Low energy — for weight loss keep calories steady; for others, small bump
            if checkIn.energyLevel <= 2 && !isWeightLoss {
                adapted.dailyCalories += 150
                adapted.carbsGrams += 20
            }

            // Feeling great — can tighten deficit for weight loss
            if checkIn.mood == .great && checkIn.energyLevel >= 4 && isWeightLoss {
                adapted.dailyCalories = max(1400, adapted.dailyCalories - 100)
            }
        }

        // Adapt based on health snapshot
        if let snapshot = healthSnapshot {
            // Poor sleep from Apple Health — boost hydration, not calories
            if snapshot.sleepHours > 0 && snapshot.sleepHours < 5 {
                adapted.hydrationOz = max(adapted.hydrationOz, 96)
                if !isWeightLoss {
                    adapted.carbsGrams += 40
                    adapted.dailyCalories = recalcCalories(adapted)
                }
            } else if snapshot.sleepHours >= 5 && snapshot.sleepHours < 6 {
                adapted.hydrationOz = max(adapted.hydrationOz, 88)
                if !isWeightLoss {
                    adapted.carbsGrams += 20
                    adapted.dailyCalories = recalcCalories(adapted)
                }
            }

            // Elevated HR — stress response, boost hydration
            if snapshot.restingHeartRate > 80 {
                adapted.hydrationOz = max(adapted.hydrationOz, 90)
            }

            // Active day — for muscle gain, add fuel. For weight loss, DO NOT increase calories.
            if snapshot.caloriesBurned > 500 && !isWeightLoss {
                let extraCals = Int((snapshot.caloriesBurned - 300) * 0.4)
                adapted.dailyCalories += extraCals
                adapted.carbsGrams += extraCals / 8
            }

            // Weight-based protein calculation
            if let weight = snapshot.weight, let goal {
                switch goal.category {
                case .muscleGain:
                    adapted.proteinGrams = max(adapted.proteinGrams, Int(weight * 1.0))
                    adapted.dailyCalories = max(adapted.dailyCalories, Int(weight * 18))
                case .weightLoss:
                    adapted.proteinGrams = max(adapted.proteinGrams, Int(weight * 0.8))
                    // Cap calories — never exceed the plan target for weight loss
                    let cap = Int(weight * 12)
                    adapted.dailyCalories = max(1400, min(cap, adapted.dailyCalories))
                default:
                    adapted.proteinGrams = max(adapted.proteinGrams, Int(weight * 0.7))
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
                adapted.tips.insert("You reported poor sleep. Prioritize an earlier bedtime tonight", at: 0)
            }

            if checkIn.sorenessLevel >= 4 {
                adapted.targetHours = max(adapted.targetHours, 8.5)
                adapted.tips.insert("High soreness detected. Extra sleep boosts muscle recovery and growth hormone", at: 0)
            }
        }

        if let snapshot = healthSnapshot {
            if snapshot.sleepHours > 0 && snapshot.sleepHours < 6 {
                adapted.targetHours = max(adapted.targetHours, 9.0)
                adapted.bedtime = "9:30 PM"
                adapted.tips.insert("You slept \(String(format: "%.1f", snapshot.sleepHours))h last night. Aim for more tonight", at: 0)
            }

            if snapshot.restingHeartRate > 80 {
                adapted.tips.insert("Elevated resting HR. Deep breathing before bed can help lower stress", at: 0)
            }
        }

        // Cap tips at 4 to avoid clutter
        if adapted.tips.count > 4 {
            adapted.tips = Array(adapted.tips.prefix(4))
        }

        return adapted
    }

    // MARK: - Insights

    static func generateInsights(
        checkIn: DailyCheckIn?,
        healthSnapshot: HealthSnapshot?,
        functionVitals: FunctionHealthVitals?,
        streakData: StreakData,
        caloriesLogged: Int = 0,
        calorieTarget: Int = 0,
        waterOz: Int = 0,
        waterTarget: Int = 0,
        isWeightLossGoal: Bool = false
    ) -> [AdaptiveInsight] {
        var insights: [AdaptiveInsight] = []

        // Calorie & hydration insights first — most actionable
        insights.append(contentsOf: nutritionInsights(
            caloriesLogged: caloriesLogged,
            calorieTarget: calorieTarget,
            waterOz: waterOz,
            waterTarget: waterTarget,
            isWeightLoss: isWeightLossGoal
        ))

        if let checkIn {
            insights.append(contentsOf: checkInInsights(checkIn, snapshot: healthSnapshot))
        }
        if let snapshot = healthSnapshot {
            insights.append(contentsOf: healthInsights(snapshot, isWeightLoss: isWeightLossGoal))
        }
        if let vitals = functionVitals {
            insights.append(contentsOf: biomarkerInsights(vitals))
        }

        // Streak — only if at risk
        if streakData.streakIsAtRisk {
            insights.append(AdaptiveInsight(
                title: "Don't Break the Chain",
                message: "Your \(streakData.currentStreak)-day streak is on the line. A check-in or workout saves it.",
                icon: "flame.fill",
                color: "orange",
                source: .streak
            ))
        }

        // Baseline coaching when no other signals are available
        if insights.isEmpty {
            insights.append(baselineInsight(isWeightLoss: isWeightLossGoal))
        }

        // Cap at 4 most relevant
        return Array(insights.prefix(4))
    }

    /// Time-of-day generic coaching when there's no personalized signal yet.
    private static func baselineInsight(isWeightLoss: Bool) -> AdaptiveInsight {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 11 {
            return AdaptiveInsight(
                title: "Start the Day Right",
                message: isWeightLoss
                    ? "Get 15 minutes of light movement in the morning. It primes your metabolism and curbs afternoon cravings."
                    : "A glass of water and 10 minutes of mobility work first thing pays back all day.",
                icon: "sun.max.fill",
                color: "yellow",
                source: .nutrition
            )
        } else if hour < 15 {
            return AdaptiveInsight(
                title: "Stay Steady",
                message: "Mid-day energy dips are usually dehydration, not hunger. Drink a glass of water before reaching for a snack.",
                icon: "drop.fill",
                color: "cyan",
                source: .nutrition
            )
        } else if hour < 20 {
            return AdaptiveInsight(
                title: "Finish Strong",
                message: isWeightLoss
                    ? "Most of your daily calories should be earlier in the day. Keep dinner protein-forward and light on carbs."
                    : "Post-workout is your best window for protein. Aim for 25-30g within an hour of training.",
                icon: "bolt.fill",
                color: "orange",
                source: .nutrition
            )
        } else {
            return AdaptiveInsight(
                title: "Wind Down",
                message: "Screens within an hour of bed lower melatonin by 50%. Dim your phone and set it down 60 minutes before sleep.",
                icon: "moon.fill",
                color: "indigo",
                source: .checkIn
            )
        }
    }

    // MARK: - Nutrition & Hydration Insights

    private static func nutritionInsights(caloriesLogged: Int, calorieTarget: Int, waterOz: Int, waterTarget: Int, isWeightLoss: Bool) -> [AdaptiveInsight] {
        var insights: [AdaptiveInsight] = []
        let hour = Calendar.current.component(.hour, from: Date())

        if calorieTarget > 0 && caloriesLogged > 0 {
            let ratio = Double(caloriesLogged) / Double(calorieTarget)

            if caloriesLogged > calorieTarget {
                let over = caloriesLogged - calorieTarget
                insights.append(AdaptiveInsight(
                    title: "Over Calorie Target",
                    message: "You're \(over) cal over your \(calorieTarget) daily target. \(isWeightLoss ? "This slows your weight loss. Consider a lighter dinner or a walk to offset." : "Try to keep dinner light to balance it out.")",
                    icon: "exclamationmark.triangle.fill",
                    color: "red",
                    source: .nutrition
                ))
            } else if ratio >= 0.85 && hour < 18 {
                let remaining = calorieTarget - caloriesLogged
                insights.append(AdaptiveInsight(
                    title: "Watch Your Calories",
                    message: "Only \(remaining) cal left and it's not dinner yet. Go for protein and veggies to stay full without going over.",
                    icon: "fork.knife",
                    color: "orange",
                    source: .nutrition
                ))
            } else if ratio >= 0.85 && hour >= 18 {
                let remaining = calorieTarget - caloriesLogged
                insights.append(AdaptiveInsight(
                    title: "Finish Strong",
                    message: "\(remaining) cal left for the evening. A light meal like grilled chicken and salad would fit perfectly.",
                    icon: "fork.knife",
                    color: "green",
                    source: .nutrition
                ))
            }
        }

        if waterTarget > 0 {
            let glasses = waterOz / 8
            let targetGlasses = waterTarget / 8
            let remaining = targetGlasses - glasses

            if remaining > 0 && hour >= 15 {
                insights.append(AdaptiveInsight(
                    title: "Drink Up",
                    message: "\(remaining) glass\(remaining == 1 ? "" : "es") to go. Dehydration kills energy and slows recovery, so keep a bottle nearby.",
                    icon: "drop.fill",
                    color: "cyan",
                    source: .nutrition
                ))
            } else if remaining > 0 && hour >= 12 {
                insights.append(AdaptiveInsight(
                    title: "Stay Hydrated",
                    message: "You're at \(glasses)/\(targetGlasses) glasses. Try to finish at least \(min(remaining, 3)) more before the afternoon's over.",
                    icon: "drop.fill",
                    color: "cyan",
                    source: .nutrition
                ))
            } else if remaining <= 0 && waterOz > 0 {
                insights.append(AdaptiveInsight(
                    title: "Hydration On Point",
                    message: "Water target hit! Your muscles and recovery thank you.",
                    icon: "drop.fill",
                    color: "green",
                    source: .nutrition
                ))
            }
        }

        return insights
    }

    // MARK: - Check-In Insights

    private static func checkInInsights(_ checkIn: DailyCheckIn, snapshot: HealthSnapshot?) -> [AdaptiveInsight] {
        var insights: [AdaptiveInsight] = []

        if checkIn.shouldSwapToRecovery {
            insights.append(AdaptiveInsight(
                title: "Take It Easy Today",
                message: "You're feeling rough, and that's okay. Today's been swapped to stretching and light movement. Recovery IS training.",
                icon: "bed.double.fill",
                color: "indigo",
                source: .checkIn
            ))
        } else if checkIn.shouldReduceIntensity {
            let reason = checkIn.sorenessLevel >= 4 ? "soreness is high" : checkIn.energyLevel <= 2 ? "energy is low" : "sleep was rough"
            insights.append(AdaptiveInsight(
                title: "Scaled Back Today",
                message: "Your \(reason), so today's workout has fewer sets and longer rest. Smart training means knowing when to pull back.",
                icon: "arrow.down.circle.fill",
                color: "orange",
                source: .checkIn
            ))
        } else if checkIn.mood == .great && checkIn.energyLevel >= 4 {
            insights.append(AdaptiveInsight(
                title: "You're Feeling It Today",
                message: "Energy's up and body feels good. Today's a great day to push. Extra sets added to your workout.",
                icon: "bolt.fill",
                color: "green",
                source: .checkIn
            ))
        }

        if checkIn.sleepRating <= 2 {
            let sleepHours = snapshot?.sleepHours
            let sleepStr = sleepHours.map { String(format: "%.1f", $0) + "h last night" } ?? "poor sleep"
            insights.append(AdaptiveInsight(
                title: "Prioritize Sleep Tonight",
                message: "You reported \(sleepStr). Aim for bed by 10 PM. Even 30 extra minutes makes a measurable difference in recovery.",
                icon: "moon.zzz.fill",
                color: "indigo",
                source: .checkIn
            ))
        }

        return insights
    }

    // MARK: - Health Data Insights

    private static func healthInsights(_ snapshot: HealthSnapshot, isWeightLoss: Bool) -> [AdaptiveInsight] {
        var insights: [AdaptiveInsight] = []

        // Sleep
        if snapshot.sleepHours > 0 && snapshot.sleepHours < 5 {
            insights.append(AdaptiveInsight(
                title: "Sleep Was Really Low",
                message: "Only \(String(format: "%.1f", snapshot.sleepHours))h. Workout intensity is reduced. Don't force it today. Focus on hydration and getting to bed earlier tonight.",
                icon: "moon.zzz.fill",
                color: "red",
                source: .appleHealth
            ))
        } else if snapshot.sleepHours >= 5 && snapshot.sleepHours < 6.5 {
            insights.append(AdaptiveInsight(
                title: "Could Use More Sleep",
                message: "\(String(format: "%.1f", snapshot.sleepHours))h isn't enough for full recovery. Your plan's adjusted, but try to get 7+ tonight.",
                icon: "moon.zzz.fill",
                color: "orange",
                source: .appleHealth
            ))
        } else if snapshot.sleepHours >= 8 {
            insights.append(AdaptiveInsight(
                title: "Well Rested",
                message: "\(String(format: "%.1f", snapshot.sleepHours))h of sleep. Your body is recovered and ready. Great day to push hard.",
                icon: "moon.stars.fill",
                color: "green",
                source: .appleHealth
            ))
        }

        // Resting HR
        if snapshot.restingHeartRate > 85 {
            insights.append(AdaptiveInsight(
                title: "Resting HR Is High",
                message: "\(Int(snapshot.restingHeartRate)) bpm is elevated. Could be stress, poor sleep, or overtraining. Today's workout is lighter. Try 5 minutes of deep breathing.",
                icon: "heart.fill",
                color: "red",
                source: .appleHealth
            ))
        } else if snapshot.restingHeartRate > 75 {
            insights.append(AdaptiveInsight(
                title: "HR Slightly Elevated",
                message: "Resting HR at \(Int(snapshot.restingHeartRate)) bpm. Not alarming, but worth monitoring. Staying hydrated and managing stress helps.",
                icon: "heart.fill",
                color: "orange",
                source: .appleHealth
            ))
        }

        // Steps / activity
        if snapshot.steps > 12000 {
            insights.append(AdaptiveInsight(
                title: "Super Active Day",
                message: "\(snapshot.steps.formatted()) steps already. Your workout is shortened since you've already earned the movement credit.",
                icon: "figure.walk",
                color: "green",
                source: .appleHealth
            ))
        } else if snapshot.steps > 0 && snapshot.steps < 3000 && Calendar.current.component(.hour, from: Date()) >= 14 {
            insights.append(AdaptiveInsight(
                title: "Get Moving",
                message: "Only \(snapshot.steps.formatted()) steps so far. Even a 15-minute walk improves mood, digestion, and sleep quality.",
                icon: "figure.walk",
                color: "orange",
                source: .appleHealth
            ))
        }

        // Active calories — context for weight loss, not a reason to eat more
        if snapshot.caloriesBurned > 500 && isWeightLoss {
            insights.append(AdaptiveInsight(
                title: "Solid Burn Today",
                message: "\(Int(snapshot.caloriesBurned)) active cal burned. Your calorie target stays the same. That burn is working toward your deficit. Don't eat it back.",
                icon: "flame.fill",
                color: "green",
                source: .appleHealth
            ))
        } else if snapshot.caloriesBurned > 500 {
            insights.append(AdaptiveInsight(
                title: "High Activity",
                message: "\(Int(snapshot.caloriesBurned)) active cal burned. Make sure you're fueling with enough protein to support recovery.",
                icon: "flame.fill",
                color: "blue",
                source: .appleHealth
            ))
        }

        return insights
    }

    // MARK: - Biomarker Insights

    private static func biomarkerInsights(_ vitals: FunctionHealthVitals) -> [AdaptiveInsight] {
        var insights: [AdaptiveInsight] = []
        let flagged = vitals.biomarkers.filter { $0.status != .normal }
        guard !flagged.isEmpty else { return insights }

        if let iron = flagged.first(where: { $0.name.lowercased().contains("iron") || $0.name.lowercased().contains("ferritin") }), iron.status == .low {
            insights.append(AdaptiveInsight(
                title: "Low Iron",
                message: "Low iron hurts energy and endurance. Add red meat, spinach, or lentils. Talk to your doctor about supplementing.",
                icon: "drop.fill",
                color: "red",
                source: .functionHealth
            ))
        }

        if let d = flagged.first(where: { $0.name.lowercased().contains("vitamin d") }), d.status == .low {
            insights.append(AdaptiveInsight(
                title: "Low Vitamin D",
                message: "Vitamin D supports bone health and recovery. Get 15 min of morning sun and consider a D3 supplement.",
                icon: "sun.max.fill",
                color: "yellow",
                source: .functionHealth
            ))
        }

        return insights
    }
}
