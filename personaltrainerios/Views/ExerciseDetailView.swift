import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) var dismiss

    private var instructions: ExerciseLibrary.Instructions {
        ExerciseLibrary.instructions(for: exercise.name)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerCard
                    if !instructions.muscleGroups.isEmpty {
                        muscleGroupChips
                    }
                    section(title: "How to Do It", icon: "list.number", color: .blue, items: instructions.steps, numbered: true)
                    if !instructions.formCues.isEmpty {
                        section(title: "Form Cues", icon: "checkmark.circle.fill", color: .green, items: instructions.formCues)
                    }
                    if !instructions.commonMistakes.isEmpty {
                        section(title: "Common Mistakes", icon: "exclamationmark.triangle.fill", color: .orange, items: instructions.commonMistakes)
                    }
                    youtubeButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Header (sets, reps, rest)

    private var headerCard: some View {
        HStack(spacing: 0) {
            statCell(value: "\(exercise.sets)", label: "sets", icon: "repeat", color: .blue)
            Divider().frame(height: 36)
            statCell(value: exercise.reps, label: "reps", icon: "number", color: .purple)
            Divider().frame(height: 36)
            statCell(value: "\(exercise.restSeconds)s", label: "rest", icon: "clock", color: .orange)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.sets) sets of \(exercise.reps) reps, \(exercise.restSeconds) seconds rest")
    }

    private func statCell(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
                .accessibilityHidden(true)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Muscle Group Chips

    private var muscleGroupChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(instructions.muscleGroups, id: \.self) { group in
                    Text(group)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.15), in: Capsule())
                        .foregroundStyle(.blue)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Targets " + instructions.muscleGroups.joined(separator: ", "))
    }

    // MARK: - Section

    private func section(title: String, icon: String, color: Color, items: [String], numbered: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.subheadline)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.headline)
            }
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                    HStack(alignment: .top, spacing: 10) {
                        if numbered {
                            Text("\(idx + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .background(color, in: Circle())
                                .accessibilityHidden(true)
                        } else {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(color)
                                .font(.system(size: 6))
                                .frame(width: 20, height: 20)
                                .accessibilityHidden(true)
                        }
                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(numbered ? "Step \(idx + 1): " : "")\(item)")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - YouTube Button

    private var youtubeButton: some View {
        Button {
            FeedbackManager.light()
            UIApplication.shared.open(ExerciseLibrary.youtubeSearchURL(for: exercise.name))
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.rectangle.fill")
                    .foregroundStyle(.red)
                    .font(.title3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Watch Demo Video")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("Opens YouTube search for \(exercise.name) form")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right.square.fill")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Watch demo video for \(exercise.name)")
        .accessibilityHint("Opens YouTube search")
    }
}
