import SwiftUI

struct TrainingPlanView: View {
    var viewModel: AppViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let plan = viewModel.trainingPlan {
                        weekHeader(plan)
                        sleepSection(plan.sleepRecommendation)
                        workoutsSection(plan.workouts)
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Training Plan")
        }
    }

    private func weekHeader(_ plan: TrainingPlan) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Week \(plan.weekNumber)")
                    .font(.title2)
                    .fontWeight(.bold)
                let completed = plan.workouts.filter(\.isCompleted).count
                Text("\(completed)/\(plan.workouts.count) workouts done")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            CircularProgress(
                progress: Double(plan.workouts.filter(\.isCompleted).count) / Double(max(plan.workouts.count, 1)),
                color: .blue
            )
            .frame(width: 50, height: 50)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func sleepSection(_ rec: SleepRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Sleep Recommendation", systemImage: "moon.fill")
                .font(.headline)
                .foregroundStyle(.indigo)
            HStack(spacing: 20) {
                VStack {
                    Text(rec.bedtime)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Bedtime")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                VStack {
                    Text(rec.wakeTime)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Wake")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack {
                    Text(String(format: "%.1fh", rec.targetHours))
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Target")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ForEach(rec.tips, id: \.self) { tip in
                HStack(alignment: .top) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                    Text(tip)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func workoutsSection(_ workouts: [Workout]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Workouts")
                .font(.headline)
            ForEach(workouts) { workout in
                WorkoutDetailCard(workout: workout) {
                    viewModel.completeWorkout(workout.id)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            Text("No Training Plan Yet")
                .font(.title2)
                .fontWeight(.bold)
            Text("Set a goal first and we'll generate a tailored training plan for you.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(40)
    }
}

struct WorkoutDetailCard: View {
    let workout: Workout
    var forceExpanded: Bool = false
    let onComplete: () -> Void
    @State private var isExpanded = false
    @State private var checkBounce = false

    init(workout: Workout, forceExpanded: Bool = false, onComplete: @escaping () -> Void) {
        self.workout = workout
        self.forceExpanded = forceExpanded
        self.onComplete = onComplete
        _isExpanded = State(initialValue: forceExpanded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    if !workout.isCompleted {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                            checkBounce = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            checkBounce = false
                        }
                        onComplete()
                    }
                } label: {
                    Image(systemName: workout.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(workout.isCompleted ? .green : Color(.systemGray3))
                        .scaleEffect(checkBounce ? 1.3 : 1.0)
                }
                .buttonStyle(.plain)

                Button {
                    FeedbackManager.light()
                    withAnimation { isExpanded.toggle() }
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(workout.day)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(workout.name)
                                .font(.headline)
                                .foregroundStyle(workout.isCompleted ? .secondary : .primary)
                                .strikethrough(workout.isCompleted)
                        }
                        Spacer()
                        HStack(spacing: 8) {
                            Text("\(workout.durationMinutes)m")
                                .font(.caption)
                                .frame(width: 40)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5), in: Capsule())
                            Text(workout.intensity.rawValue)
                                .font(.caption)
                                .frame(width: 65)
                                .padding(.vertical, 4)
                                .background(Color(workout.intensity.color).opacity(0.2), in: Capsule())
                                .foregroundStyle(Color(workout.intensity.color))
                            Image(systemName: "chevron.down")
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                                .foregroundStyle(.secondary)
                                .frame(width: 16)
                        }
                    }
                }
            }

            if isExpanded {
                Divider()
                ForEach(workout.exercises) { exercise in
                    ExerciseRow(exercise: exercise)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    @State private var showDetail = false

    var body: some View {
        Button {
            FeedbackManager.light()
            showDetail = true
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(exercise.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        Image(systemName: "info.circle")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                            .accessibilityHidden(true)
                    }
                    if let notes = exercise.notes {
                        Text(notes)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(exercise.sets) \u{00D7} \(exercise.reps)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(exercise.restSeconds)s rest")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(exercise.name), \(exercise.sets) sets of \(exercise.reps), \(exercise.restSeconds) seconds rest")
        .accessibilityHint("Tap to see how to perform this exercise")
        .sheet(isPresented: $showDetail) {
            ExerciseDetailView(exercise: exercise)
        }
    }
}

struct CircularProgress: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .fontWeight(.bold)
        }
    }
}
