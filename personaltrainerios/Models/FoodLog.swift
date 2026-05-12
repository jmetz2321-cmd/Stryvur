import Foundation

struct FoodLogEntry: Identifiable, Codable {
    let id: UUID
    var name: String
    var calories: Int
    var timestamp: Date
    var mealName: String?

    init(id: UUID = UUID(), name: String, calories: Int = 0, timestamp: Date = Date(), mealName: String? = nil) {
        self.id = id
        self.name = name
        self.calories = calories
        self.timestamp = timestamp
        self.mealName = mealName
    }
}
