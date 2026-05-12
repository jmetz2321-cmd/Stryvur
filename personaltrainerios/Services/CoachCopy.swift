import Foundation

enum CoachCopy {

    // MARK: - Dashboard Greeting

    static func greeting(name: String, streak: Int, workoutsCompleted: Int, totalWorkouts: Int, hasCheckedIn: Bool) -> String {
        let firstName = name.components(separatedBy: " ").first ?? ""
        let hour = Calendar.current.component(.hour, from: Date())

        let nameStr = firstName.isEmpty ? "" : ", \(firstName)"

        // Streak-aware greetings
        if streak >= 7 {
            return pickRandom([
                "\(streak) days strong\(nameStr) \u{1F525}",
                "Unstoppable\(nameStr) — \(streak) days in a row",
                "On fire\(nameStr)! \(streak)-day streak",
            ])
        }

        if hasCheckedIn && workoutsCompleted > 0 {
            return pickRandom([
                "Solid day so far\(nameStr) \u{1F4AA}",
                "Putting in the work\(nameStr)",
                "You showed up today\(nameStr) \u{2014} that's what counts",
            ])
        }

        // Time-of-day fallback
        if hour < 12 {
            return pickRandom([
                "Rise and grind\(nameStr) \u{2600}\u{FE0F}",
                "New day, new gains\(nameStr)",
                "Good morning\(nameStr) \u{2014} let's make it count",
            ])
        } else if hour < 17 {
            return pickRandom([
                "Keep that momentum going\(nameStr)",
                "Afternoon push\(nameStr) \u{1F4AA}",
                "Halfway through the day\(nameStr) \u{2014} stay locked in",
            ])
        } else {
            return pickRandom([
                "Strong finish tonight\(nameStr)",
                "Evening check-in\(nameStr) \u{2014} how'd you do?",
                "Winding down\(nameStr) \u{2014} you earned this rest",
            ])
        }
    }

    // MARK: - Week Progress

    static func weekProgress(completed: Int, total: Int) -> String {
        guard total > 0 else { return "No workouts scheduled this week" }
        let ratio = Double(completed) / Double(total)

        if completed == 0 {
            return pickRandom([
                "Fresh week \u{2014} let's get after it",
                "Time to get that first one done",
                "Week's wide open \u{2014} you've got this",
            ])
        } else if ratio < 0.5 {
            return pickRandom([
                "Good start \u{2014} \(total - completed) more to go",
                "Building momentum \u{2014} keep stacking wins",
                "\(completed) down, \(total - completed) to crush",
            ])
        } else if ratio < 1.0 {
            return pickRandom([
                "Finish line's close \u{2014} don't let up",
                "Almost there \u{2014} \(total - completed) left this week",
                "So close to a clean sweep",
            ])
        } else {
            return pickRandom([
                "Clean sweep \u{2014} every workout done \u{1F451}",
                "Perfect week \u{2014} you're a machine",
                "All workouts crushed. Legend status.",
            ])
        }
    }

    // MARK: - Today's Workout

    static func todayWorkoutTitle(_ workoutName: String) -> String {
        pickRandom([
            "\(workoutName) is on deck",
            "Today's challenge: \(workoutName)",
            "\(workoutName) \u{2014} let's go",
        ])
    }

    static func workoutCompleted(_ workoutName: String) -> String {
        pickRandom([
            "\(workoutName) \u{2014} crushed it \u{1F4AA}",
            "That's another one in the books!",
            "\(workoutName) done. You showed up and that's everything.",
            "Workout complete \u{2014} your future self says thanks",
        ])
    }

    // MARK: - Check-In

    static func checkInPrompt() -> String {
        pickRandom([
            "Quick check-in \u{2014} how's the body feeling?",
            "30 seconds to help dial in your plan",
            "Your coach wants to know \u{2014} how are you today?",
        ])
    }

    // MARK: - Empty States

    static func noGoalsYet() -> String {
        pickRandom([
            "Every journey starts with a destination \u{2014} set your first goal",
            "What are we training for? Set a goal and let's build your plan",
            "No goals yet \u{2014} let's give you something to chase",
        ])
    }

    static func allGoalsCompleted() -> String {
        pickRandom([
            "Every goal crushed \u{2014} time to dream bigger",
            "You did it all. What's next?",
            "Goals complete \u{2014} you're proof that consistency works",
        ])
    }

    // MARK: - Hydration

    static func hydrationEncouragement(glasses: Int, target: Int) -> String {
        let remaining = target - glasses
        if remaining <= 0 {
            return pickRandom([
                "Hydration target hit \u{2014} your body thanks you \u{1F4A7}",
                "Fully hydrated \u{2014} nice work",
            ])
        } else if remaining <= 2 {
            return "Almost there \u{2014} \(remaining) more glass\(remaining == 1 ? "" : "es") to go"
        } else {
            return "\(remaining) glasses left \u{2014} keep sipping"
        }
    }

    // MARK: - Streaks

    static func streakMessage(streak: Int) -> String {
        if streak == 0 {
            return "Start a streak today \u{2014} one day at a time"
        } else if streak < 3 {
            return "\(streak)-day streak \u{2014} building something here"
        } else if streak < 7 {
            return "\(streak) days strong \u{2014} don't break the chain"
        } else if streak < 14 {
            return "\(streak)-day streak \u{2014} you're on fire \u{1F525}"
        } else if streak < 30 {
            return "\(streak) days \u{2014} this is becoming a lifestyle"
        } else {
            return "\(streak)-day streak \u{2014} absolutely legendary \u{1F451}"
        }
    }

    // MARK: - Trends

    static func trendInsight(avgEnergy: Int, tiredDays: Int, avgSoreness: Int) -> String {
        if tiredDays >= 3 {
            return pickRandom([
                "Your body's asking for more rest \u{2014} listen to it",
                "Lots of tired days lately. Maybe dial back intensity or get to bed earlier.",
            ])
        } else if avgEnergy >= 4 {
            return pickRandom([
                "Energy's been high \u{2014} great time to push your limits",
                "You're feeling good \u{2014} let's capitalize on that",
            ])
        } else if avgSoreness >= 4 {
            return pickRandom([
                "Soreness is elevated \u{2014} prioritize recovery today",
                "Feeling beat up? Extra stretching and sleep go a long way.",
            ])
        } else {
            return pickRandom([
                "Steady week \u{2014} consistency is the real superpower",
                "Looking balanced \u{2014} keep doing what you're doing",
            ])
        }
    }

    // MARK: - Goal Progress

    static func goalEncouragement(progress: Double, title: String) -> String {
        if progress >= 1.0 {
            return "\(title) \u{2014} goal reached! You did it \u{1F3C6}"
        } else if progress >= 0.75 {
            return "So close on \(title) \u{2014} the home stretch"
        } else if progress >= 0.5 {
            return "Halfway on \(title) \u{2014} keep that momentum"
        } else if progress >= 0.25 {
            return "Making real progress on \(title)"
        } else {
            return "Just getting started \u{2014} every step counts"
        }
    }

    // MARK: - Celebration Messages (replaces functional strings)

    static func milestoneReached(_ title: String) -> String {
        pickRandom([
            "Milestone unlocked: \(title) \u{1F3AF}",
            "\(title) \u{2014} another one down!",
            "You just hit \(title) \u{2014} keep pushing",
        ])
    }

    static func goalCompleted(_ title: String) -> String {
        pickRandom([
            "\(title) \u{2014} DONE. You're proof that hard work pays off \u{1F3C6}",
            "Goal crushed: \(title)! What's next?",
            "\(title) complete \u{2014} take a moment to appreciate how far you've come",
        ])
    }

    // MARK: - Helper

    private static func pickRandom(_ options: [String]) -> String {
        options.randomElement() ?? options[0]
    }
}
