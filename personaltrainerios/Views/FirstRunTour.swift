import SwiftUI

struct FirstRunTour: View {
    @Binding var isPresented: Bool
    @State private var currentStep = 0

    private let steps: [TourStep] = [
        TourStep(
            icon: "calendar.badge.clock",
            iconColor: .blue,
            title: "Today's Workout",
            body: "Your top priority. Tap to see exercises, mark complete when done, or jump to the full plan."
        ),
        TourStep(
            icon: "flame.fill",
            iconColor: .orange,
            title: "Progress Hub",
            body: "All your stats in one place: level, points, streak, achievements, and freezes. Tap to expand."
        ),
        TourStep(
            icon: "brain.head.profile.fill",
            iconColor: .purple,
            title: "Coach's Notes",
            body: "Updates in real time as you check in, log meals, drink water, and sync health data. The more you use it, the smarter it gets."
        ),
        TourStep(
            icon: "sun.max.fill",
            iconColor: .yellow,
            title: "Daily Check-In",
            body: "30 seconds to tell us how you feel. Energy low? Workout intensity drops. Feeling great? We push harder."
        ),
        TourStep(
            icon: "heart.fill",
            iconColor: .red,
            title: "Apple Health",
            body: "Connect to sync sleep, steps, and heart rate. Toggle individual metrics on or off anytime, or disconnect completely."
        ),
        TourStep(
            icon: "fork.knife",
            iconColor: .orange,
            title: "Meal & Water Logging",
            body: "Log meals and water from the Plan tab. Your calorie tracker and Coach's Notes update the moment you log anything."
        ),
        TourStep(
            icon: "bell.fill",
            iconColor: .indigo,
            title: "Smart Notifications",
            body: "Reminders adapt to your patterns. Workout reminders show up before you usually train, not at random times."
        ),
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {}

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(steps[currentStep].iconColor.opacity(0.15))
                            .frame(width: 88, height: 88)
                        Image(systemName: steps[currentStep].icon)
                            .font(.system(size: 38))
                            .foregroundStyle(steps[currentStep].iconColor)
                    }

                    // Title & body
                    VStack(spacing: 10) {
                        Text(steps[currentStep].title)
                            .font(.title3)
                            .fontWeight(.bold)
                        Text(steps[currentStep].body)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }

                    // Progress dots
                    HStack(spacing: 6) {
                        ForEach(0..<steps.count, id: \.self) { i in
                            Circle()
                                .fill(i == currentStep ? Color.blue : Color(.systemGray4))
                                .frame(width: 7, height: 7)
                                .scaleEffect(i == currentStep ? 1.2 : 1.0)
                        }
                    }

                    // Buttons
                    VStack(spacing: 10) {
                        Button {
                            FeedbackManager.light()
                            if currentStep < steps.count - 1 {
                                withAnimation { currentStep += 1 }
                            } else {
                                dismissTour()
                            }
                        } label: {
                            Text(currentStep < steps.count - 1 ? "Next" : "Got It")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        if currentStep < steps.count - 1 {
                            Button {
                                dismissTour()
                            } label: {
                                Text("Skip tour")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(28)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .transition(.opacity)
    }

    private func dismissTour() {
        FeedbackManager.success()
        UserDefaults.standard.set(true, forKey: "hasSeenFirstRunTour")
        withAnimation { isPresented = false }
    }
}

struct TourStep {
    let icon: String
    let iconColor: Color
    let title: String
    let body: String
}
