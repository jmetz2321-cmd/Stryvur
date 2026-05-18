import SwiftUI

struct ContentView: View {
    @State private var authManager = AuthManager()
    @State private var showRatePromptDemo = false

    var body: some View {
        ZStack {
            if authManager.isSignedIn {
                MainTabView(authManager: authManager)
            } else {
                SignInView(authManager: authManager)
                    .overlay(alignment: .topLeading) {
                        // Test mode indicator for simulator
                        #if targetEnvironment(simulator)
                        Text("Tap ⭐ to demo rate prompt")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .padding(8)
                        #endif
                    }
            }

            if showRatePromptDemo {
                RateAppView {
                    showRatePromptDemo = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowRatePromptDemo"))) { _ in
            showRatePromptDemo = true
        }
        .onAppear {
            #if targetEnvironment(simulator)
            // Auto-show rate prompt after 2 seconds in simulator for demo purposes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showRatePromptDemo = true
            }
            #endif
        }
    }
}

#Preview {
    ContentView()
}
