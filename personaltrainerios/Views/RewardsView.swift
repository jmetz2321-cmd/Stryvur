import SwiftUI

struct RewardsView: View {
    var viewModel: AppViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    levelCard
                    statsGrid
                    rewardsGrid
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Rewards")
        }
    }

    private var levelCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.yellow.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: viewModel.rewardProgress.levelProgress)
                    .stroke(Color.yellow, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack {
                    Text("LVL")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.rewardProgress.level)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
            }
            .frame(width: 100, height: 100)

            Text("\(viewModel.rewardProgress.totalPoints) Total Points")
                .font(.headline)
            Text("\(viewModel.rewardProgress.pointsToNextLevel) pts to next level")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatBadge(title: "Current Streak", value: "\(viewModel.rewardProgress.currentStreak)", icon: "flame.fill", color: .orange)
            StatBadge(title: "Longest Streak", value: "\(viewModel.rewardProgress.longestStreak)", icon: "bolt.fill", color: .yellow)
            StatBadge(title: "Goals Done", value: "\(viewModel.rewardProgress.goalsCompleted)", icon: "trophy.fill", color: .green)
            StatBadge(title: "Milestones", value: "\(viewModel.rewardProgress.milestonesReached)", icon: "flag.fill", color: .blue)
        }
    }

    private var rewardsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.rewardProgress.rewards) { reward in
                    RewardBadge(reward: reward)
                }
            }
        }
    }
}

struct StatBadge: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct RewardBadge: View {
    let reward: Reward

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(reward.isUnlocked ? Color(reward.category.color).opacity(0.2) : Color(.systemGray5))
                    .frame(width: 60, height: 60)
                Image(systemName: reward.icon)
                    .font(.title2)
                    .foregroundStyle(reward.isUnlocked ? Color(reward.category.color) : .gray)
            }
            Text(reward.title)
                .font(.caption2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            if !reward.isUnlocked {
                Text("\(reward.pointsRequired) pts")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .opacity(reward.isUnlocked ? 1 : 0.5)
    }
}
