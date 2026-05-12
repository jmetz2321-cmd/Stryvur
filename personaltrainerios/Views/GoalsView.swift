import SwiftUI
import Charts

struct GoalsView: View {
    var viewModel: AppViewModel
    @State private var showAddGoal = false
    @State private var selectedGoal: UserGoal?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if viewModel.goals.isEmpty {
                        emptyState
                    } else {
                        progressChart
                        goalsList
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Goals")
            .toolbar {
                Button {
                    showAddGoal = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
            .sheet(isPresented: $showAddGoal) {
                AddGoalSheet(viewModel: viewModel)
            }
            .sheet(item: $selectedGoal) { goal in
                GoalDetailSheet(goal: goal, viewModel: viewModel)
            }
        }
    }

    // MARK: - Progress Chart

    private var progressChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Inline summary — only show when multiple goals
            if viewModel.goals.count > 1 {
                HStack(spacing: 16) {
                    let active = viewModel.goals.filter { !$0.isCompleted }.count
                    let completed = viewModel.goals.filter { $0.isCompleted }.count
                    let avgProgress = viewModel.goals.reduce(0.0) { $0 + $1.progress } / Double(viewModel.goals.count)

                    Label("\(active) Active", systemImage: "target")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Label("\(completed) Done", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Spacer()
                    Text("\(Int(avgProgress * 100))% avg")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }
            }

            // Line chart for primary active goal
            if let primary = viewModel.goals.first(where: { !$0.isCompleted }), primary.progressHistory.count >= 2 {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: primary.category.icon)
                            .foregroundStyle(Color(primary.category.color))
                            .font(.caption)
                        Text(primary.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(Int(primary.progress * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color(primary.category.color))
                    }

                    Chart {
                        ForEach(primary.progressHistory) { entry in
                            LineMark(
                                x: .value("Date", entry.date),
                                y: .value(primary.unit, entry.value)
                            )
                            .foregroundStyle(Color(primary.category.color))
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Date", entry.date),
                                y: .value(primary.unit, entry.value)
                            )
                            .foregroundStyle(Color(primary.category.color).opacity(0.1))
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", entry.date),
                                y: .value(primary.unit, entry.value)
                            )
                            .foregroundStyle(Color(primary.category.color))
                            .symbolSize(24)
                        }

                        RuleMark(y: .value("Target", primary.targetValue))
                            .foregroundStyle(.green.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("Goal: \(formatValue(primary.targetValue))")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            }
                    }
                    .frame(height: 160)
                    .chartYScale(domain: chartYDomain(for: primary))
                }
            } else if let primary = viewModel.goals.first(where: { !$0.isCompleted }) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(.secondary)
                    Text("Log progress on \"\(primary.title)\" to see your chart")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Compact Goal Rows

    private var goalsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.goals.enumerated()), id: \.element.id) { index, goal in
                Button {
                    selectedGoal = goal
                } label: {
                    GoalRow(goal: goal, viewModel: viewModel)
                }
                .buttonStyle(.plain)

                if index < viewModel.goals.count - 1 {
                    Divider().padding(.leading, 48)
                }
            }
        }
        .padding(.vertical, 4)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func chartYDomain(for goal: UserGoal) -> ClosedRange<Double> {
        let values = goal.progressHistory.map(\.value) + [goal.targetValue, goal.startingValue]
        let minVal = (values.min() ?? 0) * 0.95
        let maxVal = (values.max() ?? 100) * 1.05
        return minVal...maxVal
    }

    private func formatValue(_ value: Double) -> String {
        value == value.rounded() ? "\(Int(value))" : String(format: "%.1f", value)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            Text("Set Your First Goal")
                .font(.title2)
                .fontWeight(.bold)
            Text("What do you want to achieve? Set a fitness goal and we'll create a personalized plan for you.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button {
                showAddGoal = true
            } label: {
                Label("Add Goal", systemImage: "plus")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(40)
    }
}

// MARK: - Compact Goal Row

struct GoalRow: View {
    let goal: UserGoal
    var viewModel: AppViewModel
    @State private var newValue: String = ""

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: goal.category.icon)
                    .font(.title3)
                    .foregroundStyle(Color(goal.category.color))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(goal.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Spacer()
                        if goal.isCompleted {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                                .font(.subheadline)
                        } else {
                            Text("\(Int(goal.progress * 100))%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(Color(goal.category.color))
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    // Inline progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(goal.category.color).opacity(0.15))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(goal.category.color))
                                .frame(width: geo.size.width * goal.progress)
                        }
                    }
                    .frame(height: 5)

                    HStack {
                        Text("\(formatValue(goal.currentValue)) / \(formatValue(goal.targetValue)) \(goal.unit)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: goal.deadline).day ?? 0
                        if goal.isCompleted {
                            Text("Completed")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        } else if daysLeft > 0 {
                            Text("\(daysLeft)d left")
                                .font(.caption2)
                                .foregroundStyle(daysLeft <= 7 ? .red : .secondary)
                        } else {
                            Text("Overdue")
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }

            // Quick update inline
            if !goal.isCompleted {
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil.line")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        TextField("Update \(goal.unit)", text: $newValue)
                            .font(.caption)
                            .keyboardType(.decimalPad)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))

                    Button {
                        if let value = Double(newValue) {
                            viewModel.updateGoalProgress(goal.id, newValue: value)
                            newValue = ""
                        }
                    } label: {
                        Text("Log")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(newValue.isEmpty)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func formatValue(_ value: Double) -> String {
        value == value.rounded() ? "\(Int(value))" : String(format: "%.1f", value)
    }
}

// MARK: - Goal Detail Sheet

struct GoalDetailSheet: View {
    let goal: UserGoal
    var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showEditSheet = false
    @State private var showRemoveConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Progress ring + key stats
                    HStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .stroke(Color(goal.category.color).opacity(0.15), lineWidth: 8)
                            Circle()
                                .trim(from: 0, to: goal.progress)
                                .stroke(Color(goal.category.color), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.spring, value: goal.progress)
                            VStack(spacing: 1) {
                                Text("\(Int(goal.progress * 100))%")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(width: 80, height: 80)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Text("Start")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 45, alignment: .leading)
                                Text("\(formatValue(goal.startingValue)) \(goal.unit)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            HStack(spacing: 6) {
                                Text("Now")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                    .frame(width: 45, alignment: .leading)
                                Text("\(formatValue(goal.currentValue)) \(goal.unit)")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.blue)
                            }
                            HStack(spacing: 6) {
                                Text("Goal")
                                    .font(.caption)
                                    .foregroundStyle(Color(goal.category.color))
                                    .frame(width: 45, alignment: .leading)
                                Text("\(formatValue(goal.targetValue)) \(goal.unit)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color(goal.category.color))
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                    // Milestones
                    if !goal.milestones.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Milestones")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            ForEach(goal.milestones) { milestone in
                                HStack(spacing: 8) {
                                    Image(systemName: milestone.isReached ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(milestone.isReached ? .green : Color(.systemGray4))
                                        .font(.subheadline)
                                    Text(milestone.title)
                                        .font(.subheadline)
                                        .strikethrough(milestone.isReached)
                                        .foregroundStyle(milestone.isReached ? .secondary : .primary)
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }

                    // Deadline
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(.secondary)
                        Text("Deadline: \(goal.deadline.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: goal.deadline).day ?? 0
                        if daysLeft > 0 && !goal.isCompleted {
                            Text("\(daysLeft) days left")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(daysLeft <= 7 ? .red : .secondary)
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                    // Actions
                    HStack(spacing: 12) {
                        Button {
                            showEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)

                        Button(role: .destructive) {
                            showRemoveConfirm = true
                        } label: {
                            Label("Remove", systemImage: "trash")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(goal.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Remove this goal?", isPresented: $showRemoveConfirm, titleVisibility: .visible) {
                Button("Remove", role: .destructive) {
                    viewModel.removeGoal(goal.id)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showEditSheet) {
                EditGoalSheet(goal: goal, viewModel: viewModel)
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func formatValue(_ value: Double) -> String {
        value == value.rounded() ? "\(Int(value))" : String(format: "%.1f", value)
    }
}

// MARK: - Add / Edit Sheets

struct AddGoalSheet: View {
    var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: GoalCategory = .generalFitness
    @State private var title = ""
    @State private var targetValue = ""
    @State private var currentValue = ""
    @State private var unit = ""
    @State private var deadline = Date().addingTimeInterval(86400 * 30)

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Type") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(GoalCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }
                Section("Details") {
                    TextField("Goal Title (e.g., Lose 20 lbs)", text: $title)
                    TextField("Where are you now?", text: $currentValue)
                        .keyboardType(.decimalPad)
                    TextField(selectedCategory.isDecreasing ? "Your target (lower number)" : "Your target", text: $targetValue)
                        .keyboardType(.decimalPad)
                    TextField("Unit (lbs, miles, days...)", text: $unit)
                    DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                }
                Section {
                    Button {
                        if let target = Double(targetValue), !title.isEmpty {
                            let current = Double(currentValue) ?? 0
                            let goal = UserGoal(
                                category: selectedCategory,
                                title: title,
                                startingValue: current,
                                targetValue: target,
                                unit: unit,
                                deadline: deadline
                            )
                            viewModel.addGoal(goal)
                            dismiss()
                        }
                    } label: {
                        Text("Create Goal")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.isEmpty || targetValue.isEmpty)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct EditGoalSheet: View {
    let goal: UserGoal
    var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: GoalCategory
    @State private var title: String
    @State private var targetValue: String
    @State private var currentValue: String
    @State private var startingValue: String
    @State private var unit: String
    @State private var deadline: Date

    init(goal: UserGoal, viewModel: AppViewModel) {
        self.goal = goal
        self.viewModel = viewModel
        _selectedCategory = State(initialValue: goal.category)
        _title = State(initialValue: goal.title)
        _targetValue = State(initialValue: goal.targetValue == goal.targetValue.rounded() ? "\(Int(goal.targetValue))" : String(format: "%.1f", goal.targetValue))
        _currentValue = State(initialValue: goal.currentValue == goal.currentValue.rounded() ? "\(Int(goal.currentValue))" : String(format: "%.1f", goal.currentValue))
        _startingValue = State(initialValue: goal.startingValue == goal.startingValue.rounded() ? "\(Int(goal.startingValue))" : String(format: "%.1f", goal.startingValue))
        _unit = State(initialValue: goal.unit)
        _deadline = State(initialValue: goal.deadline)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Type") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(GoalCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }
                Section("Details") {
                    TextField("Goal Title", text: $title)
                    HStack {
                        Text("Starting Value")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("Starting", text: $startingValue)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    HStack {
                        Text("Current Value")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("Current", text: $currentValue)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    HStack {
                        Text("Target Value")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("Target", text: $targetValue)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    TextField("Unit (lbs, miles, days...)", text: $unit)
                    DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                }
                Section {
                    Button {
                        guard let target = Double(targetValue), !title.isEmpty else { return }
                        let current = Double(currentValue) ?? goal.currentValue
                        let starting = Double(startingValue) ?? goal.startingValue
                        let updated = UserGoal(
                            id: goal.id,
                            category: selectedCategory,
                            title: title,
                            startingValue: starting,
                            targetValue: target,
                            currentValue: current,
                            unit: unit,
                            deadline: deadline
                        )
                        viewModel.updateGoal(updated)
                        dismiss()
                    } label: {
                        Text("Save Changes")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.isEmpty || targetValue.isEmpty)
                }
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
