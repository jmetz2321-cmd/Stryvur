import Foundation
import Supabase

struct SupabaseService {
    private static var client: SupabaseClient { SupabaseManager.shared.client }

    // MARK: - Database Row Types

    struct GoalRow: Codable {
        let id: UUID
        var userId: String
        var category: String
        var title: String
        var startingValue: Double
        var targetValue: Double
        var currentValue: Double
        var unit: String
        var deadline: Date
        var milestones: Data
        var isCompleted: Bool

        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case category, title
            case startingValue = "starting_value"
            case targetValue = "target_value"
            case currentValue = "current_value"
            case unit, deadline, milestones
            case isCompleted = "is_completed"
        }
    }

    struct CheckInRow: Codable {
        let id: UUID
        var userId: String
        var date: Date
        var mood: String
        var energyLevel: Int
        var sorenessLevel: Int
        var sleepRating: Int
        var notes: String

        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case date, mood
            case energyLevel = "energy_level"
            case sorenessLevel = "soreness_level"
            case sleepRating = "sleep_rating"
            case notes
        }
    }

    struct FoodLogRow: Codable {
        let id: UUID
        var userId: String
        var name: String
        var calories: Int
        var timestamp: Date
        var mealName: String?

        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case name, calories, timestamp
            case mealName = "meal_name"
        }
    }

    struct StreakRow: Codable {
        var userId: String
        var currentStreak: Int
        var longestStreak: Int
        var lastActivityDate: Date?
        var streakFreezes: Int
        var freezesUsed: Int
        var totalActiveDays: Int
        var weeklyCompletions: [Date]

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case currentStreak = "current_streak"
            case longestStreak = "longest_streak"
            case lastActivityDate = "last_activity_date"
            case streakFreezes = "streak_freezes"
            case freezesUsed = "freezes_used"
            case totalActiveDays = "total_active_days"
            case weeklyCompletions = "weekly_completions"
        }
    }

    struct ManualStatsRow: Codable {
        var userId: String
        var weight: Double?
        var restingHeartRate: Double?
        var sleepHours: Double?
        var activeMinutes: Int?
        var steps: Int?
        var caloriesBurned: Double?
        var bodyFatPercentage: Double?
        var lastUpdated: Date?

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case weight
            case restingHeartRate = "resting_heart_rate"
            case sleepHours = "sleep_hours"
            case activeMinutes = "active_minutes"
            case steps
            case caloriesBurned = "calories_burned"
            case bodyFatPercentage = "body_fat_percentage"
            case lastUpdated = "last_updated"
        }
    }

    struct CheckedMealsRow: Codable {
        var userId: String
        var mealIds: [String]

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case mealIds = "meal_ids"
        }
    }

    // MARK: - Goals

    static func fetchGoals(userId: String) async throws -> [UserGoal] {
        let rows: [GoalRow] = try await client.from("goals")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        return rows.compactMap { row in
            guard let category = GoalCategory.allCases.first(where: { $0.rawValue == row.category }) else { return nil }
            let milestones = (try? JSONDecoder().decode([Milestone].self, from: row.milestones)) ?? []
            return UserGoal(
                id: row.id,
                category: category,
                title: row.title,
                startingValue: row.startingValue,
                targetValue: row.targetValue,
                currentValue: row.currentValue,
                unit: row.unit,
                deadline: row.deadline,
                milestones: milestones,
                isCompleted: row.isCompleted
            )
        }
    }

    static func upsertGoal(_ goal: UserGoal, userId: String) async throws {
        let milestonesData = (try? JSONEncoder().encode(goal.milestones)) ?? Data()
        let row = GoalRow(
            id: goal.id,
            userId: userId,
            category: goal.category.rawValue,
            title: goal.title,
            startingValue: goal.startingValue,
            targetValue: goal.targetValue,
            currentValue: goal.currentValue,
            unit: goal.unit,
            deadline: goal.deadline,
            milestones: milestonesData,
            isCompleted: goal.isCompleted
        )
        try await client.from("goals")
            .upsert(row)
            .execute()
    }

    static func deleteGoal(_ goalId: UUID, userId: String) async throws {
        try await client.from("goals")
            .delete()
            .eq("id", value: goalId.uuidString)
            .eq("user_id", value: userId)
            .execute()
    }

    // MARK: - Check-Ins

    static func fetchCheckIns(userId: String) async throws -> [DailyCheckIn] {
        let rows: [CheckInRow] = try await client.from("check_ins")
            .select()
            .eq("user_id", value: userId)
            .order("date", ascending: false)
            .execute()
            .value
        return rows.compactMap { row in
            guard let mood = DailyCheckIn.Mood(rawValue: row.mood) else { return nil }
            return DailyCheckIn(
                id: row.id,
                date: row.date,
                mood: mood,
                energyLevel: row.energyLevel,
                sorenessLevel: row.sorenessLevel,
                sleepRating: row.sleepRating,
                notes: row.notes
            )
        }
    }

    static func insertCheckIn(_ checkIn: DailyCheckIn, userId: String) async throws {
        let row = CheckInRow(
            id: checkIn.id,
            userId: userId,
            date: checkIn.date,
            mood: checkIn.mood.rawValue,
            energyLevel: checkIn.energyLevel,
            sorenessLevel: checkIn.sorenessLevel,
            sleepRating: checkIn.sleepRating,
            notes: checkIn.notes
        )
        try await client.from("check_ins")
            .insert(row)
            .execute()
    }

    // MARK: - Food Log

    static func fetchFoodLog(userId: String) async throws -> [FoodLogEntry] {
        let rows: [FoodLogRow] = try await client.from("food_log")
            .select()
            .eq("user_id", value: userId)
            .order("timestamp", ascending: false)
            .execute()
            .value
        return rows.map { row in
            FoodLogEntry(id: row.id, name: row.name, calories: row.calories, timestamp: row.timestamp, mealName: row.mealName)
        }
    }

    static func insertFoodLogEntry(_ entry: FoodLogEntry, userId: String) async throws {
        let row = FoodLogRow(id: entry.id, userId: userId, name: entry.name, calories: entry.calories, timestamp: entry.timestamp, mealName: entry.mealName)
        try await client.from("food_log")
            .insert(row)
            .execute()
    }

    static func deleteFoodLogEntry(_ entryId: UUID, userId: String) async throws {
        try await client.from("food_log")
            .delete()
            .eq("id", value: entryId.uuidString)
            .eq("user_id", value: userId)
            .execute()
    }

    // MARK: - Streak

    static func fetchStreak(userId: String) async throws -> StreakData? {
        let rows: [StreakRow] = try await client.from("streaks")
            .select()
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value
        guard let row = rows.first else { return nil }
        return StreakData(
            currentStreak: row.currentStreak,
            longestStreak: row.longestStreak,
            lastActivityDate: row.lastActivityDate,
            streakFreezes: row.streakFreezes,
            freezesUsed: row.freezesUsed,
            totalActiveDays: row.totalActiveDays,
            weeklyCompletions: row.weeklyCompletions
        )
    }

    static func upsertStreak(_ streak: StreakData, userId: String) async throws {
        let row = StreakRow(
            userId: userId,
            currentStreak: streak.currentStreak,
            longestStreak: streak.longestStreak,
            lastActivityDate: streak.lastActivityDate,
            streakFreezes: streak.streakFreezes,
            freezesUsed: streak.freezesUsed,
            totalActiveDays: streak.totalActiveDays,
            weeklyCompletions: streak.weeklyCompletions
        )
        try await client.from("streaks")
            .upsert(row)
            .execute()
    }

    // MARK: - Manual Stats

    static func fetchManualStats(userId: String) async throws -> ManualHealthStats? {
        let rows: [ManualStatsRow] = try await client.from("manual_stats")
            .select()
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value
        guard let row = rows.first else { return nil }
        return ManualHealthStats(
            weight: row.weight,
            restingHeartRate: row.restingHeartRate,
            sleepHours: row.sleepHours,
            activeMinutes: row.activeMinutes,
            steps: row.steps,
            caloriesBurned: row.caloriesBurned,
            bodyFatPercentage: row.bodyFatPercentage,
            lastUpdated: row.lastUpdated
        )
    }

    static func upsertManualStats(_ stats: ManualHealthStats, userId: String) async throws {
        let row = ManualStatsRow(
            userId: userId,
            weight: stats.weight,
            restingHeartRate: stats.restingHeartRate,
            sleepHours: stats.sleepHours,
            activeMinutes: stats.activeMinutes,
            steps: stats.steps,
            caloriesBurned: stats.caloriesBurned,
            bodyFatPercentage: stats.bodyFatPercentage,
            lastUpdated: stats.lastUpdated
        )
        try await client.from("manual_stats")
            .upsert(row)
            .execute()
    }

    // MARK: - Checked Meals

    static func fetchCheckedMeals(userId: String) async throws -> Set<String> {
        let rows: [CheckedMealsRow] = try await client.from("checked_meals")
            .select()
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value
        return Set(rows.first?.mealIds ?? [])
    }

    static func upsertCheckedMeals(_ meals: Set<String>, userId: String) async throws {
        let row = CheckedMealsRow(userId: userId, mealIds: Array(meals))
        try await client.from("checked_meals")
            .upsert(row)
            .execute()
    }
}
