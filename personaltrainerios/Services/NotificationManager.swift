import Foundation
import UserNotifications

struct NotificationManager {

    /// Identifies which destination a tapped notification should route to.
    /// Embedded in each notification's userInfo as the `route` key.
    enum Route: String {
        case checkIn       // open Morning Check-In sheet
        case workout       // open My Plan → Workouts (expand today's workout)
        case nutrition     // open My Plan → Nutrition
        case hydration     // open My Plan → Nutrition (hydration section)
        case streak        // open Today tab → Progress Hub
        case weeklySummary // open Today tab → Progress Hub
    }

    static let routeKey = "route"

    private static let allIdentifiers = [
        "dailyCheckIn", "workoutReminder", "streakAtRisk", "weeklySummary",
        "calorieWarning", "hydrationReminder"
    ]

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                scheduleAllNotifications()
            }
        }
    }

    /// Adaptive scheduling: notifications fire at times based on the user's actual behavior patterns.
    /// Falls back to sensible defaults when no behavior data exists yet.
    static func scheduleAllNotifications(
        streak: Int = 0,
        hasCheckedInToday: Bool = false,
        todayWorkoutName: String? = nil,
        caloriesLogged: Int = 0,
        calorieTarget: Int = 0,
        waterOz: Int = 0,
        waterTarget: Int = 0
    ) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: allIdentifiers)

        scheduleAdaptiveCheckIn()
        scheduleAdaptiveWorkoutReminder(workoutName: todayWorkoutName)
        if streak >= 3 {
            scheduleAdaptiveStreakAtRisk(streak: streak)
        }
        scheduleWeeklySummary()

        // Calorie warning — fires 1 hour before user's typical last meal time
        if calorieTarget > 0 && caloriesLogged >= Int(Double(calorieTarget) * 0.8) && caloriesLogged < calorieTarget {
            let remaining = calorieTarget - caloriesLogged
            scheduleAdaptiveCalorieWarning(remaining: remaining)
        }

        // Hydration reminder — fires at user's typical hydration window if behind
        if waterTarget > 0 && waterOz < waterTarget {
            let glassesLeft = (waterTarget - waterOz) / 8
            if glassesLeft > 0 {
                scheduleAdaptiveHydrationReminder(glassesLeft: glassesLeft)
            }
        }
    }

    // MARK: - Adaptive Daily Check-In

    /// Fires 30 min before the user's typical check-in time (or 8 AM default).
    /// Uses behavior data once we have at least 3 check-ins recorded.
    private static func scheduleAdaptiveCheckIn() {
        let typicalHour = BehaviorTracker.typicalCheckInHour()
        let triggerHour = max(6, typicalHour - 1) // 1 hour before typical, but never before 6 AM

        let content = UNMutableNotificationContent()
        if BehaviorTracker.hasPattern(for: .checkIn) {
            content.title = "Time for your check-in"
            content.body = "You usually check in around this time. 30 seconds to dial in your plan."
        } else {
            content.title = "Time to check in!"
            content.body = "A quick check-in keeps your plan dialed in to how you feel."
        }
        content.sound = .default
        content.userInfo = [routeKey: Route.checkIn.rawValue]

        var time = DateComponents()
        time.hour = triggerHour
        time.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyCheckIn", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Adaptive Workout Reminder

    /// Fires 30 min before the user's typical workout time (or 5 PM default).
    private static func scheduleAdaptiveWorkoutReminder(workoutName: String?) {
        let typicalHour = BehaviorTracker.typicalWorkoutHour()
        let triggerHour = max(5, typicalHour - 1)

        let content = UNMutableNotificationContent()
        let timePrefix = BehaviorTracker.hasPattern(for: .workout) ? "Almost workout time. " : ""
        if let name = workoutName {
            content.title = "\(timePrefix)\(name) is on deck"
            content.body = "Your workout is ready. Let's go."
        } else {
            content.title = "\(timePrefix)Time to train"
            content.body = "You have a workout scheduled today. Let's crush it!"
        }
        content.sound = .default
        content.userInfo = [routeKey: Route.workout.rawValue]

        var time = DateComponents()
        time.hour = triggerHour
        time.minute = 30

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(identifier: "workoutReminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Adaptive Streak at Risk

    /// Fires 2 hours before the user's typical bedtime / last activity time.
    private static func scheduleAdaptiveStreakAtRisk(streak: Int) {
        // Use the latest of workout, check-in, or meal as proxy for "still active" time
        let latestActive = max(
            BehaviorTracker.typicalWorkoutHour(),
            BehaviorTracker.typicalLastMealHour()
        )
        let triggerHour = min(22, latestActive + 1)

        let content = UNMutableNotificationContent()
        content.title = "Your \(streak)-day streak is on the line"
        content.body = "A quick check-in or workout saves it. Don't let it slip."
        content.sound = .default
        content.userInfo = [routeKey: Route.streak.rawValue]

        var time = DateComponents()
        time.hour = triggerHour
        time.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(identifier: "streakAtRisk", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Weekly Summary (Sunday at user's typical check-in time)

    private static func scheduleWeeklySummary() {
        let content = UNMutableNotificationContent()
        content.title = "Your week in review"
        content.body = "See how you did this week and check out your plan for next week."
        content.sound = .default
        content.userInfo = [routeKey: Route.weeklySummary.rawValue]

        var time = DateComponents()
        time.weekday = 1  // Sunday
        time.hour = BehaviorTracker.typicalCheckInHour()
        time.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(identifier: "weeklySummary", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Adaptive Calorie Warning

    /// Fires 1 hour before the user's typical dinner / last meal time.
    private static func scheduleAdaptiveCalorieWarning(remaining: Int) {
        let lastMealHour = BehaviorTracker.typicalLastMealHour()
        let triggerHour = max(12, lastMealHour - 1)

        let content = UNMutableNotificationContent()
        content.title = "Watch your calories"
        content.body = "You have \(remaining) cal left for today. Choose wisely for dinner."
        content.sound = .default
        content.userInfo = [routeKey: Route.nutrition.rawValue]

        var time = DateComponents()
        time.hour = triggerHour
        time.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: false)
        let request = UNNotificationRequest(identifier: "calorieWarning", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Adaptive Hydration Reminder

    /// Fires at the user's typical mid-day hydration time, or 3 PM if no pattern.
    private static func scheduleAdaptiveHydrationReminder(glassesLeft: Int) {
        let triggerHour = BehaviorTracker.typicalHydrationHour()

        let content = UNMutableNotificationContent()
        content.title = "\(glassesLeft) more glass\(glassesLeft == 1 ? "" : "es") to go"
        content.body = "Stay hydrated! You're almost at your daily water goal."
        content.sound = .default
        content.userInfo = [routeKey: Route.hydration.rawValue]

        var time = DateComponents()
        time.hour = triggerHour
        time.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: false)
        let request = UNNotificationRequest(identifier: "hydrationReminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Cancel streak-at-risk notification when user has already been active today.
    static func cancelStreakAtRisk() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["streakAtRisk"])
    }
}
