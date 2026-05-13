import SwiftUI

/// Shown once to users who installed before subscriptions launched.
/// Apple Guideline: existing users must not be cut off — we extend their free trial as a gift.
struct ExistingUserWelcomeView: View {
    var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 100, height: 100)
                    Image(systemName: "gift.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                        .accessibilityHidden(true)
                }

                VStack(spacing: 12) {
                    Text("Thanks for being here early")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    Text("Longivor is going premium. As a thank you for being an early user, you get a free month on us.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 14) {
                    bonusRow(icon: "calendar.badge.checkmark", title: "30 days free", subtitle: "Full premium access, no charge")
                    bonusRow(icon: "brain.head.profile.fill", title: "All premium features", subtitle: "Coach's Notes, history, adaptive plans")
                    bonusRow(icon: "bell.slash.fill", title: "No surprise charges", subtitle: "We'll remind you before anything renews")
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 16)

                Button {
                    FeedbackManager.success()
                    dismiss()
                } label: {
                    Text("Got It, Let's Go")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 32)

                Text("After 30 days, choose a monthly or annual plan to continue.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .interactiveDismissDisabled(true)
    }

    private func bonusRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(.purple)
                .font(.title3)
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
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
}
