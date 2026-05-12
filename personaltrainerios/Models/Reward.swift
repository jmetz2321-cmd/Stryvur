import Foundation

struct Reward: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var icon: String
    var pointsRequired: Int
    var isUnlocked: Bool
    var unlockedDate: Date?
    var category: RewardCategory

    init(id: UUID = UUID(), title: String, description: String, icon: String, pointsRequired: Int, isUnlocked: Bool = false, unlockedDate: Date? = nil, category: RewardCategory) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.pointsRequired = pointsRequired
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
        self.category = category
    }

    enum RewardCategory: String, Codable, CaseIterable {
        case streak = "Streak"
        case milestone = "Milestone"
        case goalComplete = "Goal Complete"
        case consistency = "Consistency"

        var color: String {
            switch self {
            case .streak: return "orange"
            case .milestone: return "blue"
            case .goalComplete: return "yellow"
            case .consistency: return "green"
            }
        }
    }
}

struct RewardProgress: Identifiable {
    let id = UUID()
    var totalPoints: Int
    var currentStreak: Int
    var longestStreak: Int
    var goalsCompleted: Int
    var milestonesReached: Int
    var rewards: [Reward]

    var level: Int {
        totalPoints / 100 + 1
    }

    var pointsToNextLevel: Int {
        100 - (totalPoints % 100)
    }

    var levelProgress: Double {
        Double(totalPoints % 100) / 100.0
    }
}
