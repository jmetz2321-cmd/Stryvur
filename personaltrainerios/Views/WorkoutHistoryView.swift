import SwiftUI

struct WorkoutHistoryView: View {
    var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedEntry: WorkoutHistoryEntry?

    private var entriesByMonth: [(String, [WorkoutHistoryEntry])] {
        let sorted = viewModel.workoutHistory.sorted { $0.completedAt > $1.completedAt }
        let grouped = Dictionary(grouping: sorted) { entry in
            let formatter = DateFormatter()
            formatter.dateFormat = "LLLL yyyy"
            return formatter.string(from: entry.completedAt)
        }
        return grouped.sorted { lhs, rhs in
            guard let lDate = lhs.value.first?.completedAt,
                  let rDate = rhs.value.first?.completedAt else { return false }
            return lDate > rDate
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.workoutHistory.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            statsHeader
                            ForEach(entriesByMonth, id: \.0) { month, entries in
                                monthSection(title: month, entries: entries)
                            }
                        }
                        .padding()
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedEntry) { entry in
                WorkoutHistoryDetailView(entry: entry)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
                .accessibilityHidden(true)
            Text("No Workouts Yet")
                .font(.title2)
                .fontWeight(.bold)
            Text("Once you complete workouts, you'll see your full history here with exercises, weights, and notes from every session.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(40)
        .frame(maxHeight: .infinity)
    }

    private var statsHeader: some View {
        let total = viewModel.workoutHistory.count
        let last30 = viewModel.workoutHistory.filter {
            $0.completedAt > Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        }.count
        let totalMinutes = viewModel.workoutHistory.reduce(0) { $0 + $1.durationMinutes }

        return HStack(spacing: 0) {
            historyStatCell(value: "\(total)", label: "Total")
            Divider().frame(height: 40)
            historyStatCell(value: "\(last30)", label: "Last 30 Days")
            Divider().frame(height: 40)
            historyStatCell(value: formatMinutes(totalMinutes), label: "Total Time")
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(total) total workouts, \(last30) in the last 30 days, \(formatMinutes(totalMinutes)) total time")
    }

    private func historyStatCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatMinutes(_ mins: Int) -> String {
        if mins >= 60 {
            let hours = mins / 60
            let remaining = mins % 60
            return remaining > 0 ? "\(hours)h \(remaining)m" : "\(hours)h"
        }
        return "\(mins)m"
    }

    private func monthSection(title: String, entries: [WorkoutHistoryEntry]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                    Button {
                        FeedbackManager.light()
                        selectedEntry = entry
                    } label: {
                        historyRow(entry)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(entry.name), \(formatDate(entry.completedAt)), \(entry.durationMinutes) minutes, \(entry.intensity.rawValue) intensity")
                    .accessibilityHint("Tap to view details")

                    if idx < entries.count - 1 {
                        Divider().padding(.leading, 60)
                    }
                }
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func historyRow(_ entry: WorkoutHistoryEntry) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(entry.intensity.color).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: intensityIcon(entry.intensity))
                    .foregroundStyle(Color(entry.intensity.color))
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                HStack(spacing: 8) {
                    Text(formatDate(entry.completedAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\u{2022}")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Label("\(entry.durationMinutes) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding()
        .contentShape(Rectangle())
    }

    private func intensityIcon(_ intensity: Workout.Intensity) -> String {
        switch intensity {
        case .low: return "leaf.fill"
        case .moderate: return "bolt.fill"
        case .high: return "flame.fill"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Detail View

struct WorkoutHistoryDetailView: View {
    let entry: WorkoutHistoryEntry
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Exercises")
                            .font(.headline)
                            .padding(.horizontal, 4)
                        ForEach(entry.exercises) { exercise in
                            exerciseRow(exercise)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(entry.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var headerCard: some View {
        VStack(spacing: 12) {
            HStack {
                detailStat(value: "\(entry.durationMinutes)", unit: "min", icon: "clock", color: .blue)
                Divider().frame(height: 40)
                detailStat(value: "\(entry.exercises.count)", unit: "exercises", icon: "list.bullet", color: .green)
                Divider().frame(height: 40)
                detailStat(value: entry.intensity.rawValue, unit: "intensity", icon: "bolt.fill", color: Color(entry.intensity.color))
            }

            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .accessibilityHidden(true)
                Text(formatFullDate(entry.completedAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func detailStat(value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.subheadline)
                .accessibilityHidden(true)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(unit)")
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
        ExerciseRow(exercise: exercise)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
