import SwiftUI
import AuthenticationServices

struct SignInView: View {
    var authManager: AuthManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 100, height: 100)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                }

                Text("4ever Health")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your AI-powered fitness companion")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 16) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    authManager.handleAuthorization(result)
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("We use Sign in with Apple to keep your account secure. We never see your password.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.horizontal, 40)

            Spacer()
                .frame(height: 40)
        }
        .background(Color(.systemBackground))
    }
}
