import SwiftUI

struct ContentView: View {
    @State private var authManager = AuthManager()

    var body: some View {
        if authManager.isSignedIn {
            MainTabView(authManager: authManager)
        } else {
            SignInView(authManager: authManager)
        }
    }
}

#Preview {
    ContentView()
}
