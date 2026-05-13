import Foundation

struct HealthIntegrationStatus: Codable {
    var appleHealthConnected: Bool
    var appleHealthLastSync: Date?
    var functionHealthConnected: Bool
    var functionHealthLastSync: Date?
    var functionHealthApiKey: String?

    init(appleHealthConnected: Bool = false, appleHealthLastSync: Date? = nil, functionHealthConnected: Bool = false, functionHealthLastSync: Date? = nil, functionHealthApiKey: String? = nil) {
        self.appleHealthConnected = appleHealthConnected
        self.appleHealthLastSync = appleHealthLastSync
        self.functionHealthConnected = functionHealthConnected
        self.functionHealthLastSync = functionHealthLastSync
        self.functionHealthApiKey = functionHealthApiKey
    }
}

struct FunctionHealthProfile: Codable {
    var memberId: String
    var lastTestDate: Date?
    var overallScore: Int?
    var categories: [BiomarkerCategory]

    init(memberId: String = "", lastTestDate: Date? = nil, overallScore: Int? = nil, categories: [BiomarkerCategory] = []) {
        self.memberId = memberId
        self.lastTestDate = lastTestDate
        self.overallScore = overallScore
        self.categories = categories
    }
}

struct BiomarkerCategory: Identifiable, Codable {
    let id: UUID
    var name: String
    var score: Int
    var biomarkers: [Biomarker]
    var icon: String

    init(id: UUID = UUID(), name: String, score: Int = 0, biomarkers: [Biomarker] = [], icon: String = "heart.fill") {
        self.id = id
        self.name = name
        self.score = score
        self.biomarkers = biomarkers
        self.icon = icon
    }

    var statusColor: String {
        if score >= 80 { return "green" }
        if score >= 60 { return "yellow" }
        if score >= 40 { return "orange" }
        return "red"
    }
}

struct AdaptiveInsight: Identifiable {
    let id = UUID()
    var title: String
    var message: String
    var icon: String
    var color: String
    var actionLabel: String?
    var source: InsightSource

    enum InsightSource: String {
        case appleHealth = "Apple Health"
        case functionHealth = "Function Health"
        case checkIn = "Check-in"
        case streak = "Streak"
        case nutrition = "Nutrition"
    }
}
