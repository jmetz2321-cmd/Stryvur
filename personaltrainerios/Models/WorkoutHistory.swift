import Foundation

/// A snapshot of a completed workout, preserved permanently so users can see
/// what they actually did over time, even after weekly plans regenerate.
struct WorkoutHistoryEntry: Identifiable, Codable {
    let id: UUID
    let workoutId: UUID
    let name: String
    let day: String
    let exercises: [Exercise]
    let durationMinutes: Int
    let intensity: Workout.Intensity
    let completedAt: Date
    var notes: String?

    init(
        id: UUID = UUID(),
        workoutId: UUID,
        name: String,
        day: String,
        exercises: [Exercise],
        durationMinutes: Int,
        intensity: Workout.Intensity,
        completedAt: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.workoutId = workoutId
        self.name = name
        self.day = day
        self.exercises = exercises
        self.durationMinutes = durationMinutes
        self.intensity = intensity
        self.completedAt = completedAt
        self.notes = notes
    }

    init(from workout: Workout, completedAt: Date = Date()) {
        self.id = UUID()
        self.workoutId = workout.id
        self.name = workout.name
        self.day = workout.day
        self.exercises = workout.exercises
        self.durationMinutes = workout.durationMinutes
        self.intensity = workout.intensity
        self.completedAt = completedAt
        self.notes = nil
    }
}
