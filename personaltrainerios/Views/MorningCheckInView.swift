import SwiftUI

struct MorningCheckInView: View {
    var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var mood: DailyCheckIn.Mood = .good
    @State private var energy: Int = 3
    @State private var soreness: Int = 1
    @State private var sleepRating: Int = 3
    @State private var notes = ""
    @State private var currentStep = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                TabView(selection: $currentStep) {
                    moodStep.tag(0)
                    energyStep.tag(1)
                    sorenessStep.tag(2)
                    sleepStep.tag(3)
                    notesStep.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
                bottomButtons
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { dismiss() }
                }
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(.systemGray5))
                RoundedRectangle(cornerRadius: 2)
                    .fill(.blue)
                    .frame(width: geo.size.width * Double(currentStep + 1) / 5.0)
                    .animation(.spring, value: currentStep)
            }
        }
        .frame(height: 4)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var moodStep: some View {
        VStack(spacing: 30) {
            Spacer()
            Text("How are you feeling?")
                .font(.title2)
                .fontWeight(.bold)
            HStack(spacing: 16) {
                ForEach(DailyCheckIn.Mood.allCases, id: \.self) { m in
                    Button {
                        mood = m
                    } label: {
                        VStack(spacing: 8) {
                            Text(m.emoji)
                                .font(.system(size: 40))
                            Text(m.rawValue)
                                .font(.caption)
                                .foregroundStyle(mood == m ? .primary : .secondary)
                        }
                        .padding(12)
                        .background(mood == m ? Color.blue.opacity(0.15) : Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(mood == m ? Color.blue : .clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
        }
        .padding()
    }

    private var energyStep: some View {
        VStack(spacing: 30) {
            Spacer()
            Text("Energy Level")
                .font(.title2)
                .fontWeight(.bold)
            Text("How much energy do you have right now?")
                .foregroundStyle(.secondary)
            RatingSelector(value: $energy, count: 5, icon: "bolt.fill", activeColor: .yellow)
            HStack {
                Text("Running on fumes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Ready to crush it")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            Spacer()
        }
        .padding()
    }

    private var sorenessStep: some View {
        VStack(spacing: 30) {
            Spacer()
            Text("Body Soreness")
                .font(.title2)
                .fontWeight(.bold)
            Text("How sore are you from previous workouts?")
                .foregroundStyle(.secondary)
            RatingSelector(value: $soreness, count: 5, icon: "figure.flexibility", activeColor: .purple)
            HStack {
                Text("Not sore at all")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Very sore")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            Spacer()
        }
        .padding()
    }

    private var sleepStep: some View {
        VStack(spacing: 30) {
            Spacer()
            Text("Sleep Quality")
                .font(.title2)
                .fontWeight(.bold)
            Text("How well did you sleep last night?")
                .foregroundStyle(.secondary)
            RatingSelector(value: $sleepRating, count: 5, icon: "moon.fill", activeColor: .indigo)
            HStack {
                Text("Terrible")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Slept like a baby")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            Spacer()
        }
        .padding()
    }

    private var notesStep: some View {
        VStack(spacing: 30) {
            Spacer()
            Text("Anything else?")
                .font(.title2)
                .fontWeight(.bold)
            Text("Injuries, goals for today, or anything on your mind")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            TextField("Optional notes...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            adaptiveSummary
            Spacer()
        }
        .padding()
    }

    private var adaptiveSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Adaptation")
                .font(.headline)
            if mood == .awful || mood == .tired || soreness >= 4 || sleepRating <= 2 {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.orange)
                    Text("Workout intensity will be reduced based on your check-in")
                        .font(.caption)
                }
            } else if mood == .great && energy >= 4 {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(.green)
                    Text("You're feeling strong — today's plan stays at full intensity")
                        .font(.caption)
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Today's plan looks good for how you're feeling")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var bottomButtons: some View {
        HStack {
            if currentStep > 0 {
                Button {
                    withAnimation { currentStep -= 1 }
                } label: {
                    Text("Back")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            Button {
                if currentStep < 4 {
                    withAnimation { currentStep += 1 }
                } else {
                    submitCheckIn()
                }
            } label: {
                Text(currentStep == 4 ? "Start My Day" : "Next")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func submitCheckIn() {
        let checkIn = DailyCheckIn(
            mood: mood,
            energyLevel: energy,
            sorenessLevel: soreness,
            sleepRating: sleepRating,
            notes: notes
        )
        viewModel.submitCheckIn(checkIn)
        dismiss()
    }
}

struct RatingSelector: View {
    @Binding var value: Int
    let count: Int
    let icon: String
    let activeColor: Color

    var body: some View {
        HStack(spacing: 16) {
            ForEach(1...count, id: \.self) { i in
                Button {
                    value = i
                } label: {
                    Image(systemName: icon)
                        .font(.title)
                        .foregroundStyle(i <= value ? activeColor : Color(.systemGray4))
                        .scaleEffect(i <= value ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: value)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
