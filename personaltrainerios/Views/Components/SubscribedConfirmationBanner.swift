import SwiftUI

/// Banner shown the first time a user successfully subscribes (after trial purchase or direct sub).
struct SubscribedConfirmationBanner: View {
    @State private var sparkleScale = 0.5

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 36, height: 36)
                Image(systemName: "sparkles")
                    .foregroundStyle(.white)
                    .font(.subheadline)
                    .scaleEffect(sparkleScale)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome to Premium")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Text("Coach's Notes, history, and adaptive plans are all yours.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.purple.opacity(0.25), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 12, y: 4)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welcome to Premium. Coach's Notes, history, and adaptive plans are now unlocked.")
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.15)) {
                sparkleScale = 1.0
            }
        }
    }
}
