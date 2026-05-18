import SwiftUI
import StoreKit

struct RateAppView: View {
    @Environment(\.dismiss) var dismiss
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 40)

            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 100, height: 100)
                Image(systemName: "star.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }

            VStack(spacing: 12) {
                Text("Loving Stryvur?")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text("Your feedback helps us improve. Rate us on the App Store!")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer(minLength: 16)

            VStack(spacing: 12) {
                Button {
                    requestAppStoreReview()
                } label: {
                    Text("Rate Us ⭐")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 32)

                Button {
                    dismiss()
                    onDismiss()
                } label: {
                    Text("Not Now")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .padding(.horizontal, 32)
            }

            Spacer(minLength: 40)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func requestAppStoreReview() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
        dismiss()
        onDismiss()
    }
}
