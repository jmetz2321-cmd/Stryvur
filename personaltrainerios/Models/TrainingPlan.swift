import Foundation

struct TrainingPlan: Identifiable, Codable {
    let id: UUID
    var weekNumber: Int
    var workouts: [Workout]
    var nutritionPlan: NutritionPlan
    var sleepRecommendation: SleepRecommendation

    init(id: UUID = UUID(), weekNumber: Int, workouts: [Workout], nutritionPlan: NutritionPlan, sleepRecommendation: SleepRecommendation) {
        self.id = id
        self.weekNumber = weekNumber
        self.workouts = workouts
        self.nutritionPlan = nutritionPlan
        self.sleepRecommendation = sleepRecommendation
    }
}

struct Workout: Identifiable, Codable {
    let id: UUID
    var name: String
    var day: String
    var exercises: [Exercise]
    var durationMinutes: Int
    var intensity: Intensity
    var isCompleted: Bool

    init(id: UUID = UUID(), name: String, day: String, exercises: [Exercise], durationMinutes: Int, intensity: Intensity, isCompleted: Bool = false) {
        self.id = id
        self.name = name
        self.day = day
        self.exercises = exercises
        self.durationMinutes = durationMinutes
        self.intensity = intensity
        self.isCompleted = isCompleted
    }

    enum Intensity: String, Codable {
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"

        var color: String {
            switch self {
            case .low: return "green"
            case .moderate: return "orange"
            case .high: return "red"
            }
        }
    }
}

struct Exercise: Identifiable, Codable {
    let id: UUID
    var name: String
    var sets: Int
    var reps: String
    var restSeconds: Int
    var notes: String?

    init(id: UUID = UUID(), name: String, sets: Int, reps: String, restSeconds: Int = 60, notes: String? = nil) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.restSeconds = restSeconds
        self.notes = notes
    }
}

struct NutritionPlan: Identifiable, Codable {
    let id: UUID
    var dailyCalories: Int
    var proteinGrams: Int
    var carbsGrams: Int
    var fatGrams: Int
    var meals: [Meal]
    var hydrationOz: Int

    init(id: UUID = UUID(), dailyCalories: Int, proteinGrams: Int, carbsGrams: Int, fatGrams: Int, meals: [Meal] = [], hydrationOz: Int = 64) {
        self.id = id
        self.dailyCalories = dailyCalories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.meals = meals
        self.hydrationOz = hydrationOz
    }
}

struct Meal: Identifiable, Codable {
    let id: UUID
    var name: String
    var time: String
    var foods: [String]
    var calories: Int

    init(id: UUID = UUID(), name: String, time: String, foods: [String], calories: Int) {
        self.id = id
        self.name = name
        self.time = time
        self.foods = foods
        self.calories = calories
    }
}

struct SleepRecommendation: Identifiable, Codable {
    let id: UUID
    var targetHours: Double
    var bedtime: String
    var wakeTime: String
    var tips: [String]

    init(id: UUID = UUID(), targetHours: Double = 8.0, bedtime: String = "10:30 PM", wakeTime: String = "6:30 AM", tips: [String] = []) {
        self.id = id
        self.targetHours = targetHours
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.tips = tips
    }
}
