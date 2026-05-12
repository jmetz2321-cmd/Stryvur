import SwiftUI

struct ManualStatsSheet: View {
    var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var weight: String
    @State private var restingHR: String
    @State private var sleepHours: String
    @State private var activeMinutes: String
    @State private var steps: String
    @State private var caloriesBurned: String
    @State private var bodyFat: String

    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
        let s = viewModel.manualStats
        _weight = State(initialValue: s.weight.map { String(format: "%.1f", $0) } ?? "")
        _restingHR = State(initialValue: s.restingHeartRate.map { "\(Int($0))" } ?? "")
        _sleepHours = State(initialValue: s.sleepHours.map { String(format: "%.1f", $0) } ?? "")
        _activeMinutes = State(initialValue: s.activeMinutes.map { "\($0)" } ?? "")
        _steps = State(initialValue: s.steps.map { "\($0)" } ?? "")
        _caloriesBurned = State(initialValue: s.caloriesBurned.map { "\(Int($0))" } ?? "")
        _bodyFat = State(initialValue: s.bodyFatPercentage.map { String(format: "%.1f", $0 * 100) } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Enter your stats manually if you don't use Apple Health or an Apple Watch. Your training and nutrition plan will adjust automatically.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Body") {
                    StatField(label: "Weight", placeholder: "e.g. 185", unit: "lbs", text: $weight)
                    StatField(label: "Body Fat", placeholder: "e.g. 22", unit: "%", text: $bodyFat)
                }

                Section("Activity") {
                    StatField(label: "Steps Today", placeholder: "e.g. 8000", unit: "steps", text: $steps)
                    StatField(label: "Active Minutes", placeholder: "e.g. 45", unit: "min", text: $activeMinutes)
                    StatField(label: "Calories Burned", placeholder: "e.g. 350", unit: "cal", text: $caloriesBurned)
                }

                Section("Vitals & Recovery") {
                    StatField(label: "Resting Heart Rate", placeholder: "e.g. 65", unit: "bpm", text: $restingHR)
                    StatField(label: "Sleep Last Night", placeholder: "e.g. 7.5", unit: "hours", text: $sleepHours)
                }

                Section {
                    Button {
                        save()
                    } label: {
                        Text("Save & Update Plan")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                if viewModel.manualStats.hasData, let lastUpdated = viewModel.manualStats.lastUpdated {
                    Section {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(.secondary)
                            Text("Last updated \(lastUpdated.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Enter Your Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        var stats = ManualHealthStats()
        stats.weight = Double(weight)
        stats.restingHeartRate = Double(restingHR)
        stats.sleepHours = Double(sleepHours)
        stats.activeMinutes = Int(activeMinutes)
        stats.steps = Int(steps)
        stats.caloriesBurned = Double(caloriesBurned)
        if let bf = Double(bodyFat) {
            stats.bodyFatPercentage = bf / 100.0
        }
        viewModel.updateManualStats(stats)
        dismiss()
    }
}

struct StatField: View {
    let label: String
    let placeholder: String
    let unit: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField(placeholder, text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)
        }
    }
}
