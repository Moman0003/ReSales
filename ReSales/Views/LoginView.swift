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
            VStack {
                Spacer()

                VStack(spacing: 12) {
                    // Email
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .padding(14)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Password
                    SecureField("Adgangskode", text: $password)
                        .padding(14)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    if let msg = authVM.errorMessage, !msg.isEmpty {
                        Text(msg)
                            .foregroundStyle(.red)
                            .font(.footnote)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Login
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

                    // Signup
                    Button {
                        Task {
                            await authVM.signUp(email: email, password: password)
                            if authVM.isLoggedIn { dismiss() }
                        }
                    } label: {
                        Text("Opret ny bruger")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .buttonStyle(.bordered)
                    .disabled(email.isEmpty || password.isEmpty || authVM.isLoading)

                    // Divider: "eller fortsæt med"
                    HStack(spacing: 12) {
                        Rectangle().fill(Color(.separator)).frame(height: 1)
                        Text("eller fortsæt med")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize()
                        Rectangle().fill(Color(.separator)).frame(height: 1)
                    }
                    .padding(.vertical, 8)

                    googleButton


                    if authVM.isLoading {
                        ProgressView()
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .navigationTitle("Login / Opret bruger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
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
            HStack(spacing: 10) {
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
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(.separator), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(authVM.isLoading)
    }


}

// UIKit bridge til GoogleSignIn (kun for at kunne presentere Google UI)
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
