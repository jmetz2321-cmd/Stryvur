import Foundation

/// Tracks user behavior timestamps to power adaptive notifications.
/// Each event records the hour-of-day; we compute a rolling average so
/// notifications fire at the user's natural patterns, not pre-set times.
enum BehaviorTracker {

    enum Event: String {
        case workout = "behaviorWorkoutHours"
        case checkIn = "behaviorCheckInHours"
        case mealLog = "behaviorMealLogHours"
        case waterLog = "behaviorWaterLogHours"
    }

    /// Record the current hour for a behavior. Keeps a rolling window of the last 14 events.
    static func record(_ event: Event) {
        let hour = Calendar.current.component(.hour, from: Date())
        var hours = UserDefaults.standard.array(forKey: event.rawValue) as? [Int] ?? []
        hours.append(hour)
        if hours.count > 14 { hours = Array(hours.suffix(14)) }
        UserDefaults.standard.set(hours, forKey: event.rawValue)
    }

    /// Returns the average hour the user does this behavior, or nil if no data yet.
    static func averageHour(for event: Event) -> Int? {
        guard let hours = UserDefaults.standard.array(forKey: event.rawValue) as? [Int],
              !hours.isEmpty else { return nil }
        // Use mode-ish: round average, but only return if we have at least 3 data points
        guard hours.count >= 3 else { return nil }
        let avg = Double(hours.reduce(0, +)) / Double(hours.count)
        return Int(avg.rounded())
    }

    /// Returns the user's typical workout hour, defaulting to 17 (5 PM) if no data.
    static func typicalWorkoutHour() -> Int {
        averageHour(for: .workout) ?? 17
    }

    /// Returns the user's typical check-in hour, defaulting to 8 AM.
    static func typicalCheckInHour() -> Int {
        averageHour(for: .checkIn) ?? 8
    }

    /// Returns the user's typical last-meal hour, defaulting to 19 (7 PM) for dinner.
    static func typicalLastMealHour() -> Int {
        averageHour(for: .mealLog) ?? 19
    }

    /// Returns the user's typical hydration window, defaulting to 15 (3 PM).
    static func typicalHydrationHour() -> Int {
        averageHour(for: .waterLog) ?? 15
    }

    /// Has the user established a pattern (at least 3 data points)?
    static func hasPattern(for event: Event) -> Bool {
        let hours = UserDefaults.standard.array(forKey: event.rawValue) as? [Int] ?? []
        return hours.count >= 3
    }
}
