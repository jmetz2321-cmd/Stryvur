import SwiftUI
import HealthKit

struct HealthIntegrationsView: View {
    var viewModel: AppViewModel
    @State private var showPermissionsDetail = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if !viewModel.healthKit.isAuthorized {
                        connectPrompt
                    } else {
                        connectionStatus
                        todayOverview
                        detailedMetrics
                    }
                    insightsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Health")
            .sheet(isPresented: $showPermissionsDetail) {
                HealthPermissionsSheet(viewModel: viewModel)
            }
            .task {
                if viewModel.healthKit.isAuthorized {
                    await viewModel.healthKit.fetchTodayData()
                    viewModel.refreshInsights()
                }
            }
            .refreshable {
                await viewModel.healthKit.fetchTodayData()
                viewModel.refreshInsights()
            }
        }
    }

    private var connectPrompt: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)
                .padding(.top, 20)

            Text("Connect Apple Health")
                .font(.title2)
                .fontWeight(.bold)

            Text("Allow this app to read your health data so we can personalize your training plan based on your real activity, sleep, and vitals.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                PermissionRow(icon: "figure.walk", title: "Steps & Activity", description: "Daily steps, active minutes, calories burned")
                PermissionRow(icon: "heart.fill", title: "Heart Rate", description: "Current and resting heart rate")
                PermissionRow(icon: "moon.fill", title: "Sleep", description: "Sleep duration and quality")
                PermissionRow(icon: "scalemass.fill", title: "Body Measurements", description: "Weight and body fat percentage")
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

            Button {
                Task { await viewModel.healthKit.requestAuthorization() }
            } label: {
                Label("Allow Access to Health Data", systemImage: "heart.circle.fill")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.large)

            Text("You can change these permissions anytime in Settings > Health > Data Access")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var connectionStatus: some View {
        HStack {
            Image(systemName: "heart.fill")
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("Apple Health Connected")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                Text("Syncing steps, calories, heart rate, sleep, weight")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                showPermissionsDetail = true
            } label: {
                Image(systemName: "gear")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var todayOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Health Snapshot")
                .font(.headline)

            if let snapshot = viewModel.healthKit.todaySnapshot {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    HealthMetricCard(
                        icon: "figure.walk",
                        title: "Steps",
                        value: snapshot.steps.formatted(),
                        subtitle: snapshot.steps >= 10000 ? "Goal reached!" : "\((10000 - snapshot.steps).formatted()) to 10K",
                        color: .green,
                        progress: Double(snapshot.steps) / 10000.0
                    )
                    HealthMetricCard(
                        icon: "flame.fill",
                        title: "Calories",
                        value: "\(Int(snapshot.caloriesBurned))",
                        subtitle: "active calories",
                        color: .orange,
                        progress: snapshot.caloriesBurned / 500.0
                    )
                    HealthMetricCard(
                        icon: "heart.fill",
                        title: "Heart Rate",
                        value: "\(Int(snapshot.heartRate))",
                        subtitle: "bpm current",
                        color: .red,
                        progress: nil
                    )
                    HealthMetricCard(
                        icon: "moon.fill",
                        title: "Sleep",
                        value: String(format: "%.1f", snapshot.sleepHours),
                        subtitle: "hours \u{2022} \(snapshot.sleepQuality.rawValue)",
                        color: .indigo,
                        progress: snapshot.sleepHours / 8.0
                    )
                    HealthMetricCard(
                        icon: "figure.run",
                        title: "Active Minutes",
                        value: "\(snapshot.activeMinutes)",
                        subtitle: snapshot.activeMinutes >= 30 ? "Goal reached!" : "\(30 - snapshot.activeMinutes)m to goal",
                        color: .blue,
                        progress: Double(snapshot.activeMinutes) / 30.0
                    )
                    HealthMetricCard(
                        icon: "waveform.path.ecg",
                        title: "Resting HR",
                        value: "\(Int(snapshot.restingHeartRate))",
                        subtitle: "bpm at rest",
                        color: .pink,
                        progress: nil
                    )
                }
            } else {
                HStack {
                    ProgressView()
                    Text("Loading health data...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
    }

    private var detailedMetrics: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let snapshot = viewModel.healthKit.todaySnapshot {
                if let weight = snapshot.weight {
                    HStack {
                        Image(systemName: "scalemass.fill")
                            .foregroundStyle(.purple)
                            .frame(width: 24)
                        Text("Weight")
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1f lbs", weight))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                if let bodyFat = snapshot.bodyFatPercentage {
                    HStack {
                        Image(systemName: "percent")
                            .foregroundStyle(.teal)
                            .frame(width: 24)
                        Text("Body Fat")
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1f%%", bodyFat * 100))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Insights")
                .font(.headline)
            if viewModel.adaptiveInsights.isEmpty {
                Text("Connect Apple Health to receive personalized insights based on your activity and vitals.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(viewModel.adaptiveInsights) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.red)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.green)
        }
    }
}

struct HealthMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let progress: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
                if let progress, progress >= 1.0 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let progress {
                ProgressView(value: min(progress, 1.0))
                    .tint(color)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct MiniStat: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct InsightCard: View {
    let insight: AdaptiveInsight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.icon)
                .font(.title3)
                .foregroundStyle(Color(insight.color))
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(insight.source.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5), in: Capsule())
                }
                Text(insight.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let action = insight.actionLabel {
                    Text(action)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct HealthPermissionsSheet: View {
    var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Apple Health is connected")
                    }
                }

                Section("Data We Read") {
                    PermissionDetailRow(icon: "figure.walk", title: "Steps", status: "Active")
                    PermissionDetailRow(icon: "flame.fill", title: "Active Calories", status: "Active")
                    PermissionDetailRow(icon: "figure.run", title: "Exercise Minutes", status: "Active")
                    PermissionDetailRow(icon: "heart.fill", title: "Heart Rate", status: "Active")
                    PermissionDetailRow(icon: "waveform.path.ecg", title: "Resting Heart Rate", status: "Active")
                    PermissionDetailRow(icon: "moon.fill", title: "Sleep Analysis", status: "Active")
                    PermissionDetailRow(icon: "scalemass.fill", title: "Body Mass", status: "Active")
                    PermissionDetailRow(icon: "percent", title: "Body Fat Percentage", status: "Active")
                }

                Section("How We Use Your Data") {
                    Label("Personalize workout intensity", systemImage: "dumbbell.fill")
                    Label("Adapt plans based on sleep quality", systemImage: "moon.zzz.fill")
                    Label("Monitor recovery via heart rate", systemImage: "heart.text.square.fill")
                    Label("Track progress toward your goals", systemImage: "chart.line.uptrend.xyaxis")
                }

                Section {
                    Button {
                        Task {
                            await viewModel.healthKit.requestAuthorization()
                            await viewModel.healthKit.fetchTodayData()
                        }
                    } label: {
                        Label("Refresh Permissions", systemImage: "arrow.clockwise")
                    }

                    Link(destination: URL(string: "x-apple-health://")!) {
                        Label("Open Health App", systemImage: "heart.fill")
                    }

                    Text("To modify permissions, go to Settings > Health > Data Access & Devices > Longivor")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Health Permissions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct PermissionDetailRow: View {
    let icon: String
    let title: String
    let status: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.red)
                .frame(width: 24)
            Text(title)
            Spacer()
            Text(status)
                .font(.caption)
                .foregroundStyle(.green)
        }
    }
}
