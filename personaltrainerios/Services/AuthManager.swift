import AuthenticationServices
import SwiftUI
import Observation
import Supabase

@Observable
class AuthManager {
    var isSignedIn = false
    var userName: String = ""
    var userEmail: String = ""
    var userID: String = ""

    private var client: SupabaseClient { SupabaseManager.shared.client }

    init() {
        loadUser()
        Task { await listenForAuthChanges() }
    }

    func handleAuthorization(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = credential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else { return }

            if let fullName = credential.fullName {
                let first = fullName.givenName ?? ""
                let last = fullName.familyName ?? ""
                let name = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
                if !name.isEmpty {
                    userName = name
                    UserDefaults.standard.set(name, forKey: "userName")
                }
            }

            Task {
                do {
                    let session = try await client.auth.signInWithIdToken(
                        credentials: .init(provider: .apple, idToken: tokenString)
                    )
                    await MainActor.run {
                        self.userID = session.user.id.uuidString
                        self.userEmail = session.user.email ?? credential.email ?? ""
                        self.isSignedIn = true
                        UserDefaults.standard.set(self.userID, forKey: "appleUserID")
                        UserDefaults.standard.set(self.userEmail, forKey: "userEmail")
                    }

                    // Store name in Supabase user metadata so it persists across devices
                    if !self.userName.isEmpty {
                        try? await client.auth.update(user: .init(data: ["full_name": .string(self.userName)]))
                    }
                } catch {
                    print("Supabase sign-in failed: \(error)")
                    await MainActor.run {
                        self.userID = credential.user
                        self.userEmail = credential.email ?? ""
                        self.isSignedIn = true
                        UserDefaults.standard.set(self.userID, forKey: "appleUserID")
                    }
                }
            }

        case .failure:
            break
        }
    }

    func checkExistingCredential() {
        Task {
            if let session = try? await client.auth.session {
                await MainActor.run {
                    self.userID = session.user.id.uuidString
                    self.userEmail = session.user.email ?? self.userEmail
                    self.isSignedIn = true

                    // Restore name from Supabase metadata if local is empty
                    if self.userName.isEmpty,
                       let meta = session.user.userMetadata["full_name"]?.stringValue {
                        self.userName = meta
                        UserDefaults.standard.set(meta, forKey: "userName")
                    }
                }
            } else if !userID.isEmpty {
                let provider = ASAuthorizationAppleIDProvider()
                provider.getCredentialState(forUserID: userID) { state, _ in
                    DispatchQueue.main.async {
                        self.isSignedIn = state == .authorized
                    }
                }
            }
        }
    }

    func signOut() {
        Task {
            try? await client.auth.signOut()
        }
        isSignedIn = false
        userID = ""
        userName = ""
        userEmail = ""
        UserDefaults.standard.removeObject(forKey: "appleUserID")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userEmail")
    }

    private func loadUser() {
        userID = UserDefaults.standard.string(forKey: "appleUserID") ?? ""
        userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        if !userID.isEmpty {
            isSignedIn = true
            checkExistingCredential()
        }
    }

    private func listenForAuthChanges() async {
        for await (event, session) in client.auth.authStateChanges {
            if event == .signedIn, let session {
                await MainActor.run {
                    self.userID = session.user.id.uuidString
                    self.isSignedIn = true
                }
            } else if event == .signedOut {
                await MainActor.run {
                    self.isSignedIn = false
                }
            }
        }
    }
}
