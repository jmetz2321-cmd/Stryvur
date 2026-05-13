import Foundation

enum CoachCopy {

    // MARK: - Dashboard Greeting

    static func greeting(name: String, streak: Int, workoutsCompleted: Int, totalWorkouts: Int, hasCheckedIn: Bool) -> String {
        let firstName = name.components(separatedBy: " ").first ?? ""
        let hour = Calendar.current.component(.hour, from: Date())
        let nameStr = firstName.isEmpty ? "" : ", \(firstName)"

        // After 30 days, dial back enthusiasm to avoid fatigue
        let daysActive = UserDefaults.standard.integer(forKey: "firstOpenDayOfYear")
        let currentDay = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let isVeteran = daysActive > 0 && (currentDay - daysActive) > 30

        if isVeteran {
            if hour < 12 { return "Good morning\(nameStr)" }
            if hour < 17 { return "Good afternoon\(nameStr)" }
            return "Good evening\(nameStr)"
        }

        if streak >= 7 {
            return pickRandom([
                "\(streak) days strong\(nameStr) \u{1F525}",
                "Unstoppable\(nameStr)! \(streak) days in a row",
                "On fire\(nameStr)! \(streak)-day streak",
            ])
        }

        if hasCheckedIn && workoutsCompleted > 0 {
            return pickRandom([
                "Solid day so far\(nameStr) \u{1F4AA}",
                "Putting in the work\(nameStr)",
                "You showed up today\(nameStr). That's what counts",
            ])
        }

        if hour < 12 {
            return pickRandom([
                "Rise and grind\(nameStr) \u{2600}\u{FE0F}",
                "New day, new gains\(nameStr)",
                "Good morning\(nameStr)! Let's make it count",
            ])
        } else if hour < 17 {
            return pickRandom([
                "Keep that momentum going\(nameStr)",
                "Afternoon push\(nameStr) \u{1F4AA}",
                "Halfway through the day\(nameStr). Stay locked in",
            ])
        } else {
            return pickRandom([
                "Strong finish tonight\(nameStr)",
                "Evening check-in\(nameStr). How'd you do?",
                "Winding down\(nameStr). You earned this rest",
            ])
        }
    }

    // MARK: - Week Progress

    static func weekProgress(completed: Int, total: Int) -> String {
        guard total > 0 else { return "No workouts scheduled this week" }
        let ratio = Double(completed) / Double(total)

        if completed == 0 {
            return pickRandom([
                "Fresh week. Let's get after it",
                "Time to get that first one done",
                "Week's wide open. You've got this",
            ])
        } else if ratio < 0.5 {
            return pickRandom([
                "Good start! \(total - completed) more to go",
                "Building momentum. Keep stacking wins",
                "\(completed) down, \(total - completed) to crush",
            ])
        } else if ratio < 1.0 {
            return pickRandom([
                "Finish line's close. Don't let up",
                "Almost there! \(total - completed) left this week",
                "So close to a clean sweep",
            ])
        } else {
            return pickRandom([
                "Clean sweep! Every workout done \u{1F451}",
                "Perfect week. You're a machine",
                "All workouts crushed. Legend status.",
            ])
        }
    }

    // MARK: - Today's Workout

    static func todayWorkoutTitle(_ workoutName: String) -> String {
        pickRandom([
            "\(workoutName) is on deck",
            "Today's challenge: \(workoutName)",
            "\(workoutName). Let's go",
        ])
    }

    static func workoutCompleted(_ workoutName: String) -> String {
        pickRandom([
            "\(workoutName) crushed \u{1F4AA}",
            "That's another one in the books!",
            "\(workoutName) done. You showed up and that's everything.",
            "Workout complete. Your future self says thanks",
        ])
    }

    // MARK: - Check-In

    static func checkInPrompt() -> String {
        pickRandom([
            "Quick check-in. How's the body feeling?",
            "30 seconds to help dial in your plan",
            "Your coach wants to know. How are you today?",
        ])
    }

    // MARK: - Empty States

    static func noGoalsYet() -> String {
        pickRandom([
            "Every journey starts with a destination. Set your first goal",
            "What are we training for? Set a goal and let's build your plan",
            "No goals yet. Let's give you something to chase",
        ])
    }

    static func allGoalsCompleted() -> String {
        pickRandom([
            "Every goal crushed. Time to dream bigger",
            "You did it all. What's next?",
            "Goals complete. You're proof that consistency works",
        ])
    }

    // MARK: - Hydration

    static func hydrationEncouragement(glasses: Int, target: Int) -> String {
        let remaining = target - glasses
        if remaining <= 0 {
            return pickRandom([
                "Hydration target hit! Your body thanks you \u{1F4A7}",
                "Fully hydrated. Nice work",
            ])
        } else if remaining <= 2 {
            return "Almost there! \(remaining) more glass\(remaining == 1 ? "" : "es") to go"
        } else {
            return "\(remaining) glasses left. Keep sipping"
        }
    }

    // MARK: - Streaks

    static func streakMessage(streak: Int) -> String {
        if streak == 0 {
            return "Start a streak today. One day at a time"
        } else if streak < 3 {
            return "\(streak)-day streak. Building something here"
        } else if streak < 7 {
            return "\(streak) days strong. Don't break the chain"
        } else if streak < 14 {
            return "\(streak)-day streak. You're on fire \u{1F525}"
        } else if streak < 30 {
            return "\(streak) days! This is becoming a lifestyle"
        } else {
            return "\(streak)-day streak. Absolutely legendary \u{1F451}"
        }
    }

    // MARK: - Trends

    static func trendInsight(avgEnergy: Int, tiredDays: Int, avgSoreness: Int) -> String {
        if tiredDays >= 3 {
            return pickRandom([
                "Your body's asking for more rest. Listen to it",
                "Lots of tired days lately. Maybe dial back intensity or get to bed earlier.",
            ])
        } else if avgEnergy >= 4 {
            return pickRandom([
                "Energy's been high. Great time to push your limits",
                "You're feeling good. Let's capitalize on that",
            ])
        } else if avgSoreness >= 4 {
            return pickRandom([
                "Soreness is elevated. Prioritize recovery today",
                "Feeling beat up? Extra stretching and sleep go a long way.",
            ])
        } else {
            return pickRandom([
                "Steady week. Consistency is the real superpower",
                "Looking balanced. Keep doing what you're doing",
            ])
        }
    }

    // MARK: - Goal Progress

    static func goalEncouragement(progress: Double, title: String) -> String {
        if progress >= 1.0 {
            return "\(title) reached! You did it \u{1F3C6}"
        } else if progress >= 0.75 {
            return "So close on \(title). The home stretch"
        } else if progress >= 0.5 {
            return "Halfway on \(title). Keep that momentum"
        } else if progress >= 0.25 {
            return "Making real progress on \(title)"
        } else {
            return "Just getting started. Every step counts"
        }
    }

    // MARK: - Celebration Messages

    static func milestoneReached(_ title: String) -> String {
        pickRandom([
            "Milestone unlocked: \(title) \u{1F3AF}",
            "\(title)! Another one down",
            "You just hit \(title). Keep pushing",
        ])
    }

    static func goalCompleted(_ title: String) -> String {
        pickRandom([
            "\(title) DONE. You're proof that hard work pays off \u{1F3C6}",
            "Goal crushed: \(title)! What's next?",
            "\(title) complete. Take a moment to appreciate how far you've come",
        ])
    }

    // MARK: - Helper

    /// Pick a consistent option per day so copy doesn't change on every refresh.
    /// Uses the day-of-year as a seed to rotate through options.
    private static func pickRandom(_ options: [String]) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return options[day % options.count]
    }
}
