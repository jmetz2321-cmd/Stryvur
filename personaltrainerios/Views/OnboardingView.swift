import SwiftUI

struct OnboardingView: View {
    var viewModel: AppViewModel
    let onComplete: () -> Void
    @State private var currentPage = 0
    @State private var phase: OnboardingPhase = .carousel

    // Goal setup state
    @State private var selectedCategory: GoalCategory = .generalFitness
    @State private var goalTitle = ""
    @State private var targetValue = ""
    @State private var currentValue = ""
    @State private var unit = ""
    @State private var deadline = Date().addingTimeInterval(86400 * 30)

    private enum OnboardingPhase {
        case carousel
        case pickCategory
        case goalDetails
    }

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "figure.strengthtraining.traditional",
            iconColor: .blue,
            title: "Your Personal AI Trainer",
            subtitle: "Get a training plan built around your goals, schedule, and real-time health data. Workouts, nutrition, and sleep — all in one place."
        ),
        OnboardingPage(
            icon: "target",
            iconColor: .orange,
            title: "Set Goals, Track Progress",
            subtitle: "Tell us what you want to achieve — lose weight, build muscle, improve endurance — and we'll create a step-by-step plan with milestones to keep you motivated."
        ),
        OnboardingPage(
            icon: "heart.fill",
            iconColor: .red,
            title: "Syncs with Apple Health",
            subtitle: "Connect your health data so your plan adapts to your steps, sleep, heart rate, and more. The more we know, the smarter your plan gets."
        ),
        OnboardingPage(
            icon: "waveform.path.ecg",
            iconColor: .cyan,
            title: "Adapts in Real Time",
            subtitle: "Your plan adjusts automatically based on your vitals, sleep, and activity. Connect Apple Health or enter your stats manually — either way, your plan stays current."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            switch phase {
            case .carousel:
                carouselView
            case .pickCategory:
                categoryPickerView
            case .goalDetails:
                goalDetailsView
            }
        }
        .background(Color(.systemBackground))
        .animation(.easeInOut(duration: 0.3), value: phase)
    }

    // MARK: - Carousel (existing pages)

    private var carouselView: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip") {
                    onComplete()
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding()
            }

            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 28) {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(page.iconColor.opacity(0.12))
                                .frame(width: 120, height: 120)
                            Image(systemName: page.icon)
                                .font(.system(size: 50))
                                .foregroundStyle(page.iconColor)
                        }
                        VStack(spacing: 12) {
                            Text(page.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            Text(page.subtitle)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        Spacer()
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.blue : Color(.systemGray4))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }

                if currentPage == pages.count - 1 {
                    Button {
                        withAnimation { phase = .pickCategory }
                    } label: {
                        Text("Set Your Goal")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, 40)
                } else {
                    Button {
                        withAnimation { currentPage += 1 }
                    } label: {
                        HStack {
                            Text("Next")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, 40)
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Category Picker

    private var categoryPickerView: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    withAnimation { phase = .carousel }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                }
                Spacer()
                Button("Skip") { onComplete() }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .padding()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("What's your main goal?")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("We'll build your workout, nutrition, and sleep plan around this.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(GoalCategory.allCases) { category in
                            Button {
                                selectedCategory = category
                                prefillForCategory(category)
                                withAnimation { phase = .goalDetails }
                            } label: {
                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(category.color).opacity(0.15))
                                            .frame(width: 56, height: 56)
                                        Image(systemName: category.icon)
                                            .font(.title2)
                                            .foregroundStyle(Color(category.color))
                                    }
                                    Text(category.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(category.color).opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Goal Details

    private var goalDetailsView: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    withAnimation { phase = .pickCategory }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                }
                Spacer()
                Button("Skip") { onComplete() }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .padding()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(selectedCategory.color).opacity(0.15))
                                .frame(width: 48, height: 48)
                            Image(systemName: selectedCategory.icon)
                                .font(.title3)
                                .foregroundStyle(Color(selectedCategory.color))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(selectedCategory.rawValue)
                                .font(.headline)
                            Text("Tell us a bit more so we can personalize your plan.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Form fields
                    VStack(spacing: 14) {
                        OnboardingTextField(label: "Goal name", placeholder: goalTitlePlaceholder, text: $goalTitle)
                        OnboardingTextField(label: "Where are you now?", placeholder: currentValuePlaceholder, text: $currentValue, isNumeric: true)
                        OnboardingTextField(label: selectedCategory.isDecreasing ? "Your target (lower)" : "Your target", placeholder: targetValuePlaceholder, text: $targetValue, isNumeric: true)
                        OnboardingTextField(label: "Unit", placeholder: "lbs, miles, days...", text: $unit)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Target date")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            DatePicker("", selection: $deadline, displayedComponents: .date)
                                .labelsHidden()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    }

                    // Create button
                    Button {
                        createGoalAndFinish()
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Create My Plan")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, 40)
                    .disabled(goalTitle.isEmpty || targetValue.isEmpty)

                    Text("You can always change this later in the Goals tab.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Helpers

    private var goalTitlePlaceholder: String {
        switch selectedCategory {
        case .weightLoss: return "e.g. Lose 20 lbs"
        case .muscleGain: return "e.g. Gain 10 lbs of muscle"
        case .endurance: return "e.g. Run a 5K"
        case .flexibility: return "e.g. Touch my toes"
        case .generalFitness: return "e.g. Get in shape"
        case .sleepImprovement: return "e.g. Sleep 8 hours consistently"
        }
    }

    private var currentValuePlaceholder: String {
        switch selectedCategory {
        case .weightLoss: return "e.g. 200"
        case .muscleGain: return "e.g. 160"
        case .endurance: return "e.g. 0"
        case .flexibility: return "e.g. 0"
        case .generalFitness: return "e.g. 0"
        case .sleepImprovement: return "e.g. 5.5"
        }
    }

    private var targetValuePlaceholder: String {
        switch selectedCategory {
        case .weightLoss: return "e.g. 180"
        case .muscleGain: return "e.g. 175"
        case .endurance: return "e.g. 3.1"
        case .flexibility: return "e.g. 10"
        case .generalFitness: return "e.g. 30"
        case .sleepImprovement: return "e.g. 8"
        }
    }

    private func prefillForCategory(_ category: GoalCategory) {
        switch category {
        case .weightLoss:
            goalTitle = "Lose Weight"
            unit = "lbs"
        case .muscleGain:
            goalTitle = "Build Muscle"
            unit = "lbs"
        case .endurance:
            goalTitle = "Improve Endurance"
            unit = "miles"
        case .flexibility:
            goalTitle = "Increase Flexibility"
            unit = "sessions"
        case .generalFitness:
            goalTitle = "Get Fit"
            unit = "workouts"
        case .sleepImprovement:
            goalTitle = "Better Sleep"
            unit = "hours"
        }
    }

    private func createGoalAndFinish() {
        guard let target = Double(targetValue), !goalTitle.isEmpty else { return }
        let current = Double(currentValue) ?? 0
        let goal = UserGoal(
            category: selectedCategory,
            title: goalTitle,
            startingValue: current,
            targetValue: target,
            unit: unit,
            deadline: deadline
        )
        viewModel.addGoal(goal)
        onComplete()
    }
}

// MARK: - Onboarding Text Field

private struct OnboardingTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isNumeric: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .keyboardType(isNumeric ? .decimalPad : .default)
                .padding(12)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal)
    }
}

private struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
}
