import SwiftUI
import AuthenticationServices
import UIKit

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var authVM: AuthViewModel

    @State private var email = ""
    @State private var password = ""

    @State private var currentNonce: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Login")
                        .font(.largeTitle.bold())
                        .padding(.top, 8)

                    Text("Login / Opret bruger")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Card: Email + password
                    VStack(spacing: 12) {
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .padding(12)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        SecureField("Adgangskode", text: $password)
                            .padding(12)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Card: actions
                    VStack(spacing: 10) {
                        Button {
                            Task {
                                await authVM.signIn(email: email, password: password)
                                if authVM.isLoggedIn { dismiss() }
                            }
                        } label: {
                            HStack {
                                Text("Login").font(.headline)
                                Spacer()
                                if authVM.isLoading { ProgressView() }
                            }
                            .frame(height: 48)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(email.isEmpty || password.isEmpty || authVM.isLoading)

                        Button {
                            Task {
                                await authVM.signUp(email: email, password: password)
                                if authVM.isLoggedIn { dismiss() }
                            }
                        } label: {
                            Text("Opret ny bruger")
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .font(.headline)
                        }
                        .buttonStyle(.bordered)
                        .disabled(email.isEmpty || password.isEmpty || authVM.isLoading)
                    }
                    .padding(.top, 4)

                    if let msg = authVM.errorMessage, !msg.isEmpty {
                        Text(msg)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }

                    // Divider with centered text
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 1)

                        Text("eller fortsæt med")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize()

                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 1)
                    }
                    .padding(.vertical, 6)

                    // Social buttons
                    VStack(spacing: 12) {
                        googleButton

                        SignInWithAppleButton(.signIn) { request in
                            let nonce = authVM.repo.randomNonceString()
                            currentNonce = nonce
                            request.requestedScopes = [.email]
                            request.nonce = authVM.repo.sha256(nonce)
                        } onCompletion: { result in
                            switch result {
                            case .success(let auth):
                                guard
                                    let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                                    let tokenData = credential.identityToken,
                                    let tokenString = String(data: tokenData, encoding: .utf8),
                                    let nonce = currentNonce
                                else {
                                    authVM.errorMessage = "Apple login fejlede"
                                    return
                                }

                                Task {
                                    authVM.isLoading = true
                                    authVM.errorMessage = nil
                                    defer { authVM.isLoading = false }

                                    do {
                                        authVM.currentUser = try await authVM.repo.signInWithApple(
                                            idToken: tokenString,
                                            nonce: nonce
                                        )
                                        if authVM.isLoggedIn { dismiss() }
                                    } catch {
                                        authVM.errorMessage = error.localizedDescription
                                    }
                                }

                            case .failure(let error):
                                authVM.errorMessage = error.localizedDescription
                            }
                        }
                        .frame(height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            }
        }
    }

    private var googleButton: some View {
        Button {
            guard let vc = UIApplication.shared.topMostViewController() else {
                authVM.errorMessage = "Kunne ikke finde view controller"
                return
            }
            Task {
                await authVM.signInWithGoogle(presentingVC: vc)
                if authVM.isLoggedIn { dismiss() }
            }
        } label: {
            HStack(spacing: 12) {
                Image("google_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)

                Text("Fortsæt med Google")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(authVM.isLoading)
    }
}

// UIKit bridge (kun til GoogleSignIn)
private extension UIApplication {
    func topMostViewController() -> UIViewController? {
        guard
            let scene = connectedScenes.first as? UIWindowScene,
            let window = scene.windows.first(where: { $0.isKeyWindow }),
            var top = window.rootViewController
        else { return nil }

        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
