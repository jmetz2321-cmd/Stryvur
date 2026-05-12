import Foundation
import UserNotifications

struct NotificationManager {

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

    /// Call this whenever state changes so notifications stay current.
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

        scheduleDailyCheckIn()
        scheduleWorkoutReminder(workoutName: todayWorkoutName)
        if streak >= 3 {
            scheduleStreakAtRisk(streak: streak)
        }
        scheduleWeeklySummary()

        // Calorie warning — schedule at 6 PM if over 80% of target
        if calorieTarget > 0 && caloriesLogged >= Int(Double(calorieTarget) * 0.8) && caloriesLogged < calorieTarget {
            let remaining = calorieTarget - caloriesLogged
            scheduleCalorieWarning(remaining: remaining)
        }

        // Hydration reminder — schedule at 3 PM if under target
        if waterTarget > 0 && waterOz < waterTarget {
            let glassesLeft = (waterTarget - waterOz) / 8
            if glassesLeft > 0 {
                scheduleHydrationReminder(glassesLeft: glassesLeft)
            }
        }
    }

    // MARK: - 1. Daily Check-In — 8:00 AM

    private static func scheduleDailyCheckIn() {
        let content = UNMutableNotificationContent()
        content.title = "Time to check in!"
        content.body = "A quick check-in keeps your plan dialed in to how you feel."
        content.sound = .default

        var time = DateComponents()
        time.hour = 8
        time.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyCheckIn", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - 2. Workout Reminder — 5:00 PM

    private static func scheduleWorkoutReminder(workoutName: String?) {
        let content = UNMutableNotificationContent()
        if let name = workoutName {
            content.title = "\(name) is on deck"
            content.body = "Your workout is ready. Let's go."
        } else {
            content.title = "Time to train!"
            content.body = "You have a workout scheduled today. Let's crush it!"
        }
        content.sound = .default

        var time = DateComponents()
        time.hour = 17
        time.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(identifier: "workoutReminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - 3. Streak at Risk — 7:00 PM

    private static func scheduleStreakAtRisk(streak: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Your \(streak)-day streak is on the line"
        content.body = "A quick check-in or workout saves it. Don't let it slip."
        content.sound = .default

        var time = DateComponents()
        time.hour = 19
        time.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(identifier: "streakAtRisk", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - 4. Weekly Summary — Sunday 6:00 PM

    private static func scheduleWeeklySummary() {
        let content = UNMutableNotificationContent()
        content.title = "Your week in review"
        content.body = "See how you did this week and check out your plan for next week."
        content.sound = .default

        var time = DateComponents()
        time.weekday = 1  // Sunday
        time.hour = 18
        time.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(identifier: "weeklySummary", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - 5. Calorie Warning — 6:00 PM

    private static func scheduleCalorieWarning(remaining: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Watch your calories"
        content.body = "You have \(remaining) cal left for today. Choose wisely for dinner."
        content.sound = .default

        var time = DateComponents()
        time.hour = 18
        time.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: false)
        let request = UNNotificationRequest(identifier: "calorieWarning", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - 6. Hydration Reminder — 3:00 PM

    private static func scheduleHydrationReminder(glassesLeft: Int) {
        let content = UNMutableNotificationContent()
        content.title = "\(glassesLeft) more glass\(glassesLeft == 1 ? "" : "es") to go"
        content.body = "Stay hydrated — you're almost at your daily water goal."
        content.sound = .default

        var time = DateComponents()
        time.hour = 15
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
