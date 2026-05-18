import SwiftUI
import StoreKit

struct ContentView: View {
    @State private var authManager = AuthManager()

    var body: some View {
        Group {
            if authManager.isSignedIn {
                MainTabView(authManager: authManager)
            } else {
                SignInView(authManager: authManager)
            }
        }
        .onAppear {
            #if DEBUG && targetEnvironment(simulator)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: scene)
                }
            }
            #endif
        }
    }
}

#Preview {
    ContentView()
}
