import Foundation

struct HealthSnapshot: Identifiable {
    let id = UUID()
    var date: Date
    var steps: Int
    var caloriesBurned: Double
    var activeMinutes: Int
    var heartRate: Double
    var restingHeartRate: Double
    var sleepHours: Double
    var sleepQuality: SleepQuality
    var weight: Double?
    var bodyFatPercentage: Double?

    enum SleepQuality: String, Codable {
        case poor = "Poor"
        case fair = "Fair"
        case good = "Good"
        case excellent = "Excellent"

        var color: String {
            switch self {
            case .poor: return "red"
            case .fair: return "orange"
            case .good: return "green"
            case .excellent: return "blue"
            }
        }
    }
}

struct FunctionHealthVitals: Identifiable, Codable {
    let id: UUID
    var date: Date
    var biomarkers: [Biomarker]

    init(id: UUID = UUID(), date: Date = Date(), biomarkers: [Biomarker] = []) {
        self.id = id
        self.date = date
        self.biomarkers = biomarkers
    }
}

struct Biomarker: Identifiable, Codable {
    let id: UUID
    var name: String
    var value: Double
    var unit: String
    var normalRange: ClosedRange<Double>
    var category: String

    init(id: UUID = UUID(), name: String, value: Double, unit: String, normalRange: ClosedRange<Double>, category: String) {
        self.id = id
        self.name = name
        self.value = value
        self.unit = unit
        self.normalRange = normalRange
        self.category = category
    }

    var status: BiomarkerStatus {
        if normalRange.contains(value) { return .normal }
        if value < normalRange.lowerBound { return .low }
        return .high
    }

    enum BiomarkerStatus: String {
        case low = "Low"
        case normal = "Normal"
        case high = "High"

        var color: String {
            switch self {
            case .low: return "blue"
            case .normal: return "green"
            case .high: return "red"
            }
        }
    }
}
