import SwiftUI

struct StreakView: View {
    var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 20) {
            streakHeader
            weekCalendar
            streakFreezes
            streakMilestones
        }
    }

    private var streakHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        viewModel.streakData.currentStreak > 0
                            ? LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Color(.systemGray4), Color(.systemGray5)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 100, height: 100)
                VStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                    Text("\(viewModel.streakData.currentStreak)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }
            Text("Day Streak")
                .font(.headline)

            if viewModel.streakData.streakIsAtRisk {
                Label("Streak at risk! Complete an activity today.", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1), in: Capsule())
            }

            HStack(spacing: 20) {
                VStack {
                    Text("\(viewModel.streakData.longestStreak)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Longest")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Divider().frame(height: 30)
                VStack {
                    Text("\(viewModel.streakData.totalActiveDays)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Total Days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Divider().frame(height: 30)
                VStack {
                    Text("\(viewModel.streakData.thisWeekCount)/7")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("This Week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var weekCalendar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)
            HStack(spacing: 8) {
                ForEach(weekDays(), id: \.label) { day in
                    VStack(spacing: 6) {
                        Text(day.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        ZStack {
                            Circle()
                                .fill(day.isCompleted ? Color.orange : day.isToday ? Color.blue.opacity(0.2) : Color(.systemGray6))
                                .frame(width: 36, height: 36)
                            if day.isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            } else if day.isToday {
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2)
                                    .frame(width: 36, height: 36)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var streakFreezes: some View {
        HStack {
            Image(systemName: "snowflake")
                .font(.title2)
                .foregroundStyle(.cyan)
            VStack(alignment: .leading, spacing: 2) {
                Text("Streak Freezes")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Protect your streak on rest days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 4) {
                ForEach(0..<viewModel.streakData.streakFreezes, id: \.self) { i in
                    Image(systemName: "snowflake")
                        .foregroundStyle(i < viewModel.streakData.availableFreezes ? .cyan : Color(.systemGray4))
                }
            }

            if viewModel.streakData.streakIsAtRisk && viewModel.streakData.canUseFreeze {
                Button("Use") {
                    viewModel.useStreakFreeze()
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .controlSize(.small)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var streakMilestones: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streak Milestones")
                .font(.headline)
            let milestones = [(3, "3 Days", "bolt.fill"), (7, "1 Week", "crown.fill"), (14, "2 Weeks", "shield.fill"), (30, "1 Month", "trophy.fill"), (100, "100 Days", "star.fill")]
            ForEach(milestones, id: \.0) { days, label, icon in
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(viewModel.streakData.longestStreak >= days ? .yellow : Color(.systemGray4))
                        .frame(width: 24)
                    Text(label)
                        .font(.subheadline)
                    Spacer()
                    if viewModel.streakData.longestStreak >= days {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Text("\(days - viewModel.streakData.currentStreak) days to go")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private struct WeekDay {
        let label: String
        let isCompleted: Bool
        let isToday: Bool
    }

    private func weekDays() -> [WeekDay] {
        let calendar = Calendar.current
        let today = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else { return [] }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: weekInterval.start)!
            let isToday = calendar.isDateInToday(date)
            let isCompleted = viewModel.streakData.weeklyCompletions.contains { calendar.isDate($0, inSameDayAs: date) }
            return WeekDay(label: formatter.string(from: date), isCompleted: isCompleted, isToday: isToday)
        }
    }
}
