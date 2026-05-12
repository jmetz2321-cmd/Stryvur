import Foundation

struct ManualHealthStats: Codable {
    var weight: Double?
    var restingHeartRate: Double?
    var sleepHours: Double?
    var activeMinutes: Int?
    var steps: Int?
    var caloriesBurned: Double?
    var bodyFatPercentage: Double?
    var lastUpdated: Date?

    var hasData: Bool {
        weight != nil || restingHeartRate != nil || sleepHours != nil ||
        activeMinutes != nil || steps != nil || caloriesBurned != nil
    }

    func toSnapshot() -> HealthSnapshot {
        let sleepQuality: HealthSnapshot.SleepQuality
        if let hours = sleepHours {
            if hours >= 8 { sleepQuality = .excellent }
            else if hours >= 7 { sleepQuality = .good }
            else if hours >= 5.5 { sleepQuality = .fair }
            else { sleepQuality = .poor }
        } else {
            sleepQuality = .fair
        }

        return HealthSnapshot(
            date: Date(),
            steps: steps ?? 0,
            caloriesBurned: caloriesBurned ?? 0,
            activeMinutes: activeMinutes ?? 0,
            heartRate: restingHeartRate ?? 0,
            restingHeartRate: restingHeartRate ?? 0,
            sleepHours: sleepHours ?? 0,
            sleepQuality: sleepQuality,
            weight: weight,
            bodyFatPercentage: bodyFatPercentage
        )
    }
}
