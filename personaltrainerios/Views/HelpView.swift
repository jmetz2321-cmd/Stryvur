import SwiftUI

struct HelpView: View {
    var authManager: AuthManager?
    @Environment(\.dismiss) var dismiss
    @State private var expandedSection: String?
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var presentedLegal: LegalDocument?

    private let sections: [HelpSection] = [
        HelpSection(
            id: "getting-started",
            icon: "sparkles",
            iconColor: .blue,
            title: "Getting Started",
            items: [
                HelpItem(q: "How does the app personalize my plan?",
                         a: "Your plan adapts based on your goal, daily check-ins, Apple Health data (sleep, heart rate, steps), and what you log in the app. The more data you give it, the smarter it gets."),
                HelpItem(q: "Do I need to use Apple Health?",
                         a: "No, but it's recommended. You can enter your stats manually instead. With Apple Health connected, your plan automatically adjusts based on sleep, activity, and heart rate."),
                HelpItem(q: "What's the daily check-in for?",
                         a: "Tracking mood, energy, soreness, and sleep tells us if you should push hard or take it easy today. It takes 30 seconds and directly changes your workout intensity."),
            ]
        ),
        HelpSection(
            id: "workouts",
            icon: "figure.run",
            iconColor: .red,
            title: "Workouts",
            items: [
                HelpItem(q: "How are workouts chosen?",
                         a: "Based on your goal (weight loss, muscle gain, etc.) and adapted in real time. If you're sore or tired, intensity drops. If you're feeling great, we add sets and shorten rest."),
                HelpItem(q: "Can I undo a completed workout?",
                         a: "Yes. Right after marking complete, an Undo button appears at the bottom for 4 seconds. Tap it to revert."),
                HelpItem(q: "What if I miss a workout?",
                         a: "Nothing bad happens. Streaks pause but freezes protect them. Get back to it the next day, or use a Streak Freeze."),
            ]
        ),
        HelpSection(
            id: "nutrition",
            icon: "fork.knife",
            iconColor: .orange,
            title: "Nutrition & Calories",
            items: [
                HelpItem(q: "Do calories adjust when I burn more?",
                         a: "For weight loss goals, no. Your daily calorie target stays fixed so the deficit works. For muscle gain, calories increase to fuel recovery."),
                HelpItem(q: "How do I log food?",
                         a: "Open the My Plan tab → Nutrition → Food Log section. Tap Add to log meals. You can also check off planned meals."),
                HelpItem(q: "What if I go over my calorie target?",
                         a: "Coach's Notes will flag it. For weight loss, we suggest a lighter dinner or a walk to offset. The app won't shame you."),
            ]
        ),
        HelpSection(
            id: "streaks",
            icon: "flame.fill",
            iconColor: .orange,
            title: "Streaks & Rewards",
            items: [
                HelpItem(q: "What counts as a streak day?",
                         a: "Doing a check-in, completing a workout, or logging progress on a goal. Any one of those keeps your streak alive."),
                HelpItem(q: "What's a Streak Freeze?",
                         a: "A streak freeze protects your streak on rest days. You earn one every 7 days. Used automatically when prompted."),
                HelpItem(q: "How do I earn points?",
                         a: "+10 for check-ins, +15 for completed workouts, +20 for hitting calorie + meal targets, +25 for milestones, +100 for completed goals."),
            ]
        ),
        HelpSection(
            id: "health-data",
            icon: "heart.fill",
            iconColor: .pink,
            title: "Health Data",
            items: [
                HelpItem(q: "How do I disconnect Apple Health?",
                         a: "Dashboard → Health section → slider icon → Disconnect Apple Health. To fully revoke, also go to iOS Settings → Health → Data Access & Devices."),
                HelpItem(q: "Can I hide certain metrics?",
                         a: "Yes. Health section → slider icon → toggle off any metric you don't want to see. Your plan still uses the data in the background."),
                HelpItem(q: "Where does my data go?",
                         a: "Health data stays on your device. Goals, check-ins, and progress sync securely to your account so you don't lose them."),
            ]
        ),
        HelpSection(
            id: "notifications",
            icon: "bell.fill",
            iconColor: .yellow,
            title: "Notifications",
            items: [
                HelpItem(q: "When do notifications fire?",
                         a: "Notifications adapt to when you actually use the app. After a few days, check-in reminders fire around your usual time, workout reminders before you typically train, etc."),
                HelpItem(q: "How do I turn them off?",
                         a: "iOS Settings → Notifications → Longivor. You can disable all or pick which types you receive."),
            ]
        ),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Help & FAQ")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Quick answers to common questions about how Longivor works.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                    ForEach(sections) { section in
                        helpSectionView(section)
                    }

                    // Legal
                    VStack(spacing: 0) {
                        legalRow(icon: "lock.shield.fill", iconColor: .green, title: "Privacy Policy") {
                            presentedLegal = .privacy
                        }
                        Divider().padding(.leading, 56)
                        legalRow(icon: "doc.text.fill", iconColor: .gray, title: "Terms of Use") {
                            presentedLegal = .terms
                        }
                    }
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)

                    // Delete Account (Apple Guideline 5.1.1(v) requirement)
                    if authManager != nil {
                        VStack(spacing: 0) {
                            Button {
                                FeedbackManager.warning()
                                showDeleteConfirm = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "trash.fill")
                                        .foregroundStyle(.red)
                                        .frame(width: 28)
                                        .accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Delete Account")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.red)
                                        Text("Permanently delete your account and all data")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(isDeleting)
                        }
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                    }

                    // Version
                    Text("Longivor v1.0.0")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $presentedLegal) { doc in
                LegalView(document: doc)
            }
            .confirmationDialog("Delete your account?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete Permanently", role: .destructive) {
                    isDeleting = true
                    Task {
                        await authManager?.deleteAccount()
                        await MainActor.run {
                            isDeleting = false
                            dismiss()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your account, goals, check-ins, food logs, streaks, and all other data. This action cannot be undone.")
            }
        }
    }

    private func legalRow(icon: String, iconColor: Color, title: String, trailing: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                if let trailing {
                    Text(trailing)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func helpSectionView(_ section: HelpSection) -> some View {
        VStack(spacing: 0) {
            Button {
                FeedbackManager.light()
                withAnimation {
                    expandedSection = expandedSection == section.id ? nil : section.id
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: section.icon)
                        .font(.title3)
                        .foregroundStyle(section.iconColor)
                        .frame(width: 28)
                    Text(section.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(expandedSection == section.id ? 90 : 0))
                }
                .padding()
            }
            .buttonStyle(.plain)

            if expandedSection == section.id {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(section.items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.q)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(item.a)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }
}

struct HelpSection: Identifiable {
    let id: String
    let icon: String
    let iconColor: Color
    let title: String
    let items: [HelpItem]
}

struct HelpItem: Identifiable {
    let id = UUID()
    let q: String
    let a: String
}
