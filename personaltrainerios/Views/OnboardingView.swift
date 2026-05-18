import SwiftUI
import StoreKit

struct OnboardingView: View {
    var viewModel: AppViewModel
    var subscriptionManager: SubscriptionManager
    let onComplete: () -> Void
    @State private var currentPage = 0
    @State private var phase: OnboardingPhase = .carousel

    // Goal setup state
    @State private var selectedCategory: GoalCategory = .generalFitness
    @State private var prefillTitle = ""
    @State private var prefillUnit = ""
    @State private var isConnectingHealth = false

    private enum OnboardingPhase {
        case carousel
        case pickCategory
        case goalDetails
        case planPreview
        case trialOffer
        case connectHealth
    }

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "figure.strengthtraining.traditional",
            iconColor: .blue,
            title: "Your Personal AI Trainer",
            subtitle: "Get a training plan built around your goals, schedule, and real-time health data. Workouts, nutrition, and sleep all in one place."
        ),
        OnboardingPage(
            icon: "target",
            iconColor: .orange,
            title: "Set Goals, Track Progress",
            subtitle: "Tell us what you want to achieve. Whether it's losing weight, building muscle, or improving endurance, we'll create a step-by-step plan with milestones to keep you motivated."
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
            subtitle: "Your plan adjusts automatically based on your vitals, sleep, and activity. Connect Apple Health or enter your stats manually. Either way, your plan stays current."
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
            case .planPreview:
                planPreviewView
            case .trialOffer:
                trialOfferView
            case .connectHealth:
                connectHealthView
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
                                .fill(page.iconColor.opacity(0.18))
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
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.orange.opacity(0.25), .pink.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 96, height: 96)
                        Image(systemName: "target")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                    .padding(.top, 20)

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
                                            .fill(LinearGradient(
                                                colors: [category.tint.opacity(0.35), category.tint.opacity(0.15)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                            .frame(width: 64, height: 64)
                                        Image(systemName: category.icon)
                                            .font(.system(size: 28, weight: .semibold))
                                            .foregroundStyle(category.tint)
                                    }
                                    Text(category.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 22)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(category.tint.opacity(0.35), lineWidth: 1.5)
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
                                .fill(selectedCategory.tint.opacity(0.15))
                                .frame(width: 48, height: 48)
                            Image(systemName: selectedCategory.icon)
                                .font(.title3)
                                .foregroundStyle(selectedCategory.tint)
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

                    GoalDetailsForm(
                        initialTitle: prefillTitle,
                        initialUnit: prefillUnit,
                        goalTitlePlaceholder: goalTitlePlaceholder,
                        currentValuePlaceholder: currentValuePlaceholder,
                        targetValuePlaceholder: targetValuePlaceholder,
                        targetLabel: selectedCategory.isDecreasing ? "Your target (lower)" : "Your target",
                        onCreate: { title, current, target, unitText, date in
                            createGoalAndFinish(title: title, current: current, target: target, unitText: unitText, date: date)
                        }
                    )
                    .id(selectedCategory)
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
            prefillTitle = "Lose Weight"
            prefillUnit = "lbs"
        case .muscleGain:
            prefillTitle = "Build Muscle"
            prefillUnit = "lbs"
        case .endurance:
            prefillTitle = "Improve Endurance"
            prefillUnit = "miles"
        case .flexibility:
            prefillTitle = "Increase Flexibility"
            prefillUnit = "sessions"
        case .generalFitness:
            prefillTitle = "Get Fit"
            prefillUnit = "workouts"
        case .sleepImprovement:
            prefillTitle = "Better Sleep"
            prefillUnit = "hours"
        }
    }

    private func createGoalAndFinish(title: String, current: Double, target: Double, unitText: String, date: Date) {
        guard !title.isEmpty else { return }
        let goal = UserGoal(
            category: selectedCategory,
            title: title,
            startingValue: current,
            targetValue: target,
            unit: unitText,
            deadline: date
        )
        viewModel.addGoal(goal)
        FeedbackManager.success()
        withAnimation { phase = .planPreview }
    }

    // MARK: - Plan Preview

    private var planPreviewView: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip") { onComplete() }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .padding()

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.20))
                                .frame(width: 80, height: 80)
                            Image(systemName: "checkmark")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.green)
                        }
                        Text("Your Plan Is Ready")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Built around your \(selectedCategory.rawValue.lowercased()) goal")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 12)

                    VStack(spacing: 12) {
                        previewRow(icon: "figure.run", iconColor: .blue, title: workoutCount, subtitle: "Weekly workouts tailored to your goal")
                        previewRow(icon: "fork.knife", iconColor: .orange, title: nutritionSummary, subtitle: "Daily calorie and macro targets")
                        previewRow(icon: "moon.fill", iconColor: .indigo, title: sleepSummary, subtitle: "Recommended bedtime and target")
                        previewRow(icon: "flag.fill", iconColor: .purple, title: "4 Milestones", subtitle: "Progress checkpoints to keep you on track")
                    }
                    .padding(.horizontal)

                    Button {
                        withAnimation { phase = .connectHealth }
                    } label: {
                        HStack {
                            Text("Continue")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                }
                .padding(.bottom, 32)
            }
        }
    }

    private func previewRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.20))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var workoutCount: String {
        let count = viewModel.trainingPlan?.workouts.count ?? 0
        return "\(count) Workouts Per Week"
    }

    private var nutritionSummary: String {
        guard let plan = viewModel.trainingPlan?.nutritionPlan else { return "Nutrition Plan" }
        return "\(plan.dailyCalories) Cal / Day"
    }

    private var sleepSummary: String {
        guard let rec = viewModel.trainingPlan?.sleepRecommendation else { return "Sleep Plan" }
        return "\(String(format: "%.1f", rec.targetHours))h Sleep Target"
    }

    // MARK: - Trial Offer (Free Trial Paywall)

    private var trialOfferView: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip") {
                    onComplete()
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            }
            .padding()

            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 84, height: 84)
                            Image(systemName: "sparkles")
                                .font(.system(size: 38))
                                .foregroundStyle(.white)
                                .accessibilityHidden(true)
                        }
                        Text("Start Your 7-Day Free Trial")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Full access to AI Coach and adaptive workouts. No charge for 7 days.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    VStack(spacing: 10) {
                        trialFeatureRow("brain.head.profile.fill", .purple, "AI Coach's Notes that adapt in real time")
                        trialFeatureRow("figure.run", .blue, "Workouts that flex with your energy")
                        trialFeatureRow("fork.knife", .orange, "Smart nutrition and hydration tracking")
                        trialFeatureRow("clock.arrow.circlepath", .indigo, "Full workout history, always saved")
                    }
                    .padding(.horizontal, 24)

                    if subscriptionManager.products.isEmpty {
                        VStack(spacing: 8) {
                            trialFallbackOption(isAnnual: true)
                            trialFallbackOption(isAnnual: false)
                        }
                        .padding(.horizontal, 24)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(subscriptionManager.products, id: \.id) { product in
                                trialProductOption(product)
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    postTrialAccessExplainer
                        .padding(.horizontal, 24)

                    Button {
                        guard let product = (selectedTrialProduct ?? subscriptionManager.products.last) else { return }
                        FeedbackManager.medium()
                        Task {
                            await subscriptionManager.purchase(product)
                        }
                    } label: {
                        Text("Start 7-Day Free Trial")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, 32)
                    .disabled(subscriptionManager.products.isEmpty)

                    Text("Cancel anytime in Settings before day 7 — no charge. If you cancel, you keep Apple Health sync and manual logging, but AI Coach insights turn off.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 32)
            }
        }
        .onChange(of: subscriptionManager.isSubscribed) { _, subscribed in
            if subscribed {
                FeedbackManager.success()
                onComplete()
            }
        }
    }

    @State private var selectedTrialProduct: Product?

    private func trialFeatureRow(_ icon: String, _ color: Color, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
                .frame(width: 28)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var postTrialAccessExplainer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("After your 7-day trial")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Paid", systemImage: "sparkles")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.purple)
                    Text("AI Coach's Notes")
                        .font(.caption)
                    Text("Adaptive workouts")
                        .font(.caption)
                    Text("Personalized nutrition")
                        .font(.caption)
                    Text("All Health insights")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Label("Free", systemImage: "person")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Text("Apple Health sync")
                        .font(.caption)
                    Text("Manual logging")
                        .font(.caption)
                    Text("Workout history")
                        .font(.caption)
                    Text("No AI Coach")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func trialFallbackOption(isAnnual: Bool) -> some View {
        trialOptionCard(
            isSelected: isAnnual,
            isAnnual: isAnnual,
            price: isAnnual ? SubscriptionManager.annualDisplayPrice : SubscriptionManager.monthlyDisplayPrice,
            cadence: isAnnual ? "/ year" : "/ month",
            secondaryLine: isAnnual ? "\(SubscriptionManager.annualEffectiveMonthly) / month, billed annually" : "Cancel anytime",
            action: {}
        )
        .opacity(0.6)
    }

    private func trialProductOption(_ product: Product) -> some View {
        let isSelected = selectedTrialProduct?.id == product.id || (selectedTrialProduct == nil && product.id == subscriptionManager.products.last?.id)
        let isAnnual = product.id.contains("annual")
        return trialOptionCard(
            isSelected: isSelected,
            isAnnual: isAnnual,
            price: product.displayPrice,
            cadence: isAnnual ? "/ year" : "/ month",
            secondaryLine: isAnnual ? "\(SubscriptionManager.annualEffectiveMonthly) / month, billed annually" : "Cancel anytime",
            action: {
                FeedbackManager.light()
                selectedTrialProduct = product
            }
        )
    }

    private func trialOptionCard(isSelected: Bool, isAnnual: Bool, price: String, cadence: String, secondaryLine: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : Color(.systemGray3))
                    .font(.title3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(isAnnual ? "Annual" : "Monthly")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        if isAnnual {
                            Text("Save 48%")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.green, in: Capsule())
                        }
                    }
                    Text(secondaryLine)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(price)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                    Text(cadence)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Connect Apple Health

    private var connectHealthView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.18))
                        .frame(width: 120, height: 120)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.red)
                }

                VStack(spacing: 12) {
                    Text("Connect Apple Health")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Your plan gets smarter with real data. We'll use your steps, sleep, heart rate, and activity to personalize everything.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(spacing: 12) {
                    if isConnectingHealth {
                        ProgressView()
                            .controlSize(.large)
                            .padding(.vertical, 12)
                        Text("Setting things up...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Button {
                            isConnectingHealth = true
                            Task {
                                await viewModel.healthKit.requestAuthorization()
                                FeedbackManager.success()
                                await MainActor.run {
                                    isConnectingHealth = false
                                    withAnimation { phase = .trialOffer }
                                }
                            }
                        } label: {
                            Label("Connect Apple Health", systemImage: "heart.circle.fill")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .controlSize(.large)
                        .padding(.horizontal, 40)

                        Button {
                            withAnimation { phase = .trialOffer }
                        } label: {
                            Text("Maybe Later")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Goal Details Form (isolated for typing perf)

private struct GoalDetailsForm: View {
    let initialTitle: String
    let initialUnit: String
    let goalTitlePlaceholder: String
    let currentValuePlaceholder: String
    let targetValuePlaceholder: String
    let targetLabel: String
    let onCreate: (String, Double, Double, String, Date) -> Void

    @State private var goalTitle: String
    @State private var currentValue = ""
    @State private var targetValue = ""
    @State private var unit: String
    @State private var deadline = Date().addingTimeInterval(86400 * 30)

    init(initialTitle: String, initialUnit: String, goalTitlePlaceholder: String, currentValuePlaceholder: String, targetValuePlaceholder: String, targetLabel: String, onCreate: @escaping (String, Double, Double, String, Date) -> Void) {
        self.initialTitle = initialTitle
        self.initialUnit = initialUnit
        self.goalTitlePlaceholder = goalTitlePlaceholder
        self.currentValuePlaceholder = currentValuePlaceholder
        self.targetValuePlaceholder = targetValuePlaceholder
        self.targetLabel = targetLabel
        self.onCreate = onCreate
        _goalTitle = State(initialValue: initialTitle)
        _unit = State(initialValue: initialUnit)
    }

    enum Field: Hashable { case goalTitle, current, target, unit }
    @FocusState private var focus: Field?

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 14) {
                OnboardingTextField(label: "Goal name", placeholder: goalTitlePlaceholder, text: $goalTitle)
                    .focused($focus, equals: .goalTitle)
                OnboardingTextField(label: "Where are you now?", placeholder: currentValuePlaceholder, text: $currentValue, isNumeric: true)
                    .focused($focus, equals: .current)
                OnboardingTextField(label: targetLabel, placeholder: targetValuePlaceholder, text: $targetValue, isNumeric: true)
                    .focused($focus, equals: .target)
                OnboardingTextField(label: "Unit", placeholder: "lbs, miles, days...", text: $unit)
                    .focused($focus, equals: .unit)

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

            Button {
                focus = nil
                let current = Double(currentValue) ?? 0
                guard let target = Double(targetValue) else { return }
                onCreate(goalTitle, current, target, unit, deadline)
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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus = nil }
            }
        }
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
                .submitLabel(.done)
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
