import Foundation

struct DailyCheckIn: Identifiable, Codable {
    let id: UUID
    var date: Date
    var mood: Mood
    var energyLevel: Int
    var sorenessLevel: Int
    var sleepRating: Int
    var notes: String

    init(id: UUID = UUID(), date: Date = Date(), mood: Mood = .good, energyLevel: Int = 3, sorenessLevel: Int = 1, sleepRating: Int = 3, notes: String = "") {
        self.id = id
        self.date = date
        self.mood = mood
        self.energyLevel = energyLevel
        self.sorenessLevel = sorenessLevel
        self.sleepRating = sleepRating
        self.notes = notes
    }

    enum Mood: String, Codable, CaseIterable {
        case great = "Great"
        case good = "Good"
        case okay = "Okay"
        case tired = "Tired"
        case awful = "Awful"

        var emoji: String {
            switch self {
            case .great: return "🔥"
            case .good: return "😊"
            case .okay: return "😐"
            case .tired: return "😴"
            case .awful: return "😫"
            }
        }

        var intensityModifier: Double {
            switch self {
            case .great: return 1.1
            case .good: return 1.0
            case .okay: return 0.85
            case .tired: return 0.7
            case .awful: return 0.5
            }
        }
    }

    var shouldReduceIntensity: Bool {
        mood == .tired || mood == .awful || sorenessLevel >= 4 || sleepRating <= 2
    }

    var shouldSwapToRecovery: Bool {
        mood == .awful || (sorenessLevel >= 4 && sleepRating <= 2)
    }
}

struct StreakData: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var lastActivityDate: Date?
    var streakFreezes: Int
    var freezesUsed: Int
    var totalActiveDays: Int
    var weeklyCompletions: [Date]

    init(currentStreak: Int = 0, longestStreak: Int = 0, lastActivityDate: Date? = nil, streakFreezes: Int = 1, freezesUsed: Int = 0, totalActiveDays: Int = 0, weeklyCompletions: [Date] = []) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastActivityDate = lastActivityDate
        self.streakFreezes = streakFreezes
        self.freezesUsed = freezesUsed
        self.totalActiveDays = totalActiveDays
        self.weeklyCompletions = weeklyCompletions
    }

    var streakIsAtRisk: Bool {
        guard let last = lastActivityDate else { return false }
        let hoursSince = Date().timeIntervalSince(last) / 3600
        return hoursSince > 20 && hoursSince < 48
    }

    var streakIsBroken: Bool {
        guard let last = lastActivityDate else { return currentStreak > 0 }
        return Date().timeIntervalSince(last) / 3600 > 48
    }

    var canUseFreeze: Bool {
        streakFreezes > freezesUsed
    }

    var availableFreezes: Int {
        streakFreezes - freezesUsed
    }

    var thisWeekCount: Int {
        let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return weeklyCompletions.filter { $0 >= startOfWeek }.count
    }
}
