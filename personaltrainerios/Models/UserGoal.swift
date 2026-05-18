import Foundation
import SwiftUI

enum GoalCategory: String, CaseIterable, Codable, Identifiable {
    case weightLoss = "Lose Weight"
    case muscleGain = "Build Muscle"
    case endurance = "Improve Endurance"
    case flexibility = "Increase Flexibility"
    case generalFitness = "General Fitness"
    case sleepImprovement = "Better Sleep"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .weightLoss: return "chart.line.downtrend.xyaxis"
        case .muscleGain: return "figure.strengthtraining.traditional"
        case .endurance: return "figure.run"
        case .flexibility: return "figure.flexibility"
        case .generalFitness: return "figure.mixed.cardio"
        case .sleepImprovement: return "bed.double.fill"
        }
    }

    var color: String {
        switch self {
        case .weightLoss: return "orange"
        case .muscleGain: return "red"
        case .endurance: return "blue"
        case .flexibility: return "purple"
        case .generalFitness: return "green"
        case .sleepImprovement: return "indigo"
        }
    }

    var tint: Color {
        switch self {
        case .weightLoss: return .orange
        case .muscleGain: return .red
        case .endurance: return .blue
        case .flexibility: return .purple
        case .generalFitness: return .green
        case .sleepImprovement: return .indigo
        }
    }

    var isDecreasing: Bool {
        self == .weightLoss
    }
}

struct ProgressEntry: Identifiable, Codable {
    let id: UUID
    var date: Date
    var value: Double

    init(id: UUID = UUID(), date: Date = Date(), value: Double) {
        self.id = id
        self.date = date
        self.value = value
    }
}

struct UserGoal: Identifiable, Codable {
    let id: UUID
    var category: GoalCategory
    var title: String
    var startingValue: Double
    var targetValue: Double
    var currentValue: Double
    var unit: String
    var deadline: Date
    var milestones: [Milestone]
    var isCompleted: Bool
    var progressHistory: [ProgressEntry]

    var totalDistance: Double {
        abs(startingValue - targetValue)
    }

    var distanceCovered: Double {
        if category.isDecreasing {
            return max(startingValue - currentValue, 0)
        } else {
            return max(currentValue - startingValue, 0)
        }
    }

    var remaining: Double {
        max(totalDistance - distanceCovered, 0)
    }

    var progress: Double {
        guard totalDistance > 0 else { return 0 }
        return min(distanceCovered / totalDistance, 1.0)
    }

    var hasReachedGoal: Bool {
        if category.isDecreasing {
            return currentValue <= targetValue
        } else {
            return currentValue >= targetValue
        }
    }

    init(id: UUID = UUID(), category: GoalCategory, title: String, startingValue: Double, targetValue: Double, currentValue: Double? = nil, unit: String, deadline: Date, milestones: [Milestone] = [], isCompleted: Bool = false, progressHistory: [ProgressEntry]? = nil) {
        self.id = id
        self.category = category
        self.title = title
        self.startingValue = startingValue
        self.targetValue = targetValue
        self.currentValue = currentValue ?? startingValue
        self.unit = unit
        self.deadline = deadline
        self.milestones = milestones
        self.isCompleted = isCompleted
        self.progressHistory = progressHistory ?? [ProgressEntry(date: Date(), value: currentValue ?? startingValue)]
    }
}

struct Milestone: Identifiable, Codable {
    let id: UUID
    var title: String
    var targetValue: Double
    var isReached: Bool

    init(id: UUID = UUID(), title: String, targetValue: Double, isReached: Bool = false) {
        self.id = id
        self.title = title
        self.targetValue = targetValue
        self.isReached = isReached
    }
}
