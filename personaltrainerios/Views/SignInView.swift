import SwiftUI
import AuthenticationServices

struct SignInView: View {
    var authManager: AuthManager
    @Environment(\.colorScheme) var colorScheme
    @State private var showRateAppPreview = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Image("Image")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)

                VStack(spacing: 8) {
                    Text("Stryvur")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Your AI-powered fitness companion")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 40)

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
            .padding(.bottom, 50)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showRateAppPreview) {
            RateAppView {
                showRateAppPreview = false
            }
        }
        .overlay(alignment: .topTrailing) {
            // Debug button - tap to show rate prompt demo
            Button {
                #if targetEnvironment(simulator)
                NotificationCenter.default.post(name: NSNotification.Name("ShowRatePromptDemo"), object: nil)
                #endif
            } label: {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.orange)
                    .padding()
            }
            .opacity(0.7)
        }
    }
}
