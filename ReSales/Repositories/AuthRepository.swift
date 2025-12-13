//
//  AuthRepository.swift
//  ReSales
//
//  Created by Moman Shafique on 13/12/2025.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit

final class AuthRepository {

    private let auth: Auth

    init(auth: Auth = Auth.auth()) {
        self.auth = auth
    }

    var currentUser: User? {
        auth.currentUser
    }

    func signIn(email: String, password: String) async throws -> User {
        try await auth.signIn(withEmail: email, password: password)
        guard let user = auth.currentUser else {
            throw NSError(domain: "AuthError", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Login failed"
            ])
        }
        return user
    }

    func signUp(email: String, password: String) async throws -> User {
        try await auth.createUser(withEmail: email, password: password)
        guard let user = auth.currentUser else {
            throw NSError(domain: "AuthError", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Signup failed"
            ])
        }
        return user
    }

    func signOut() throws {
        try auth.signOut()
    }
    
    func signInWithGoogle(presentingVC: UIViewController) async throws -> User {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw NSError(domain: "AuthRepository", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Firebase clientID mangler. Tjek GoogleService-Info.plist og FirebaseApp.configure()"
                ])
            }

            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC)

            guard let idToken = result.user.idToken?.tokenString else {
                throw NSError(domain: "AuthRepository", code: -2, userInfo: [
                    NSLocalizedDescriptionKey: "Google ID token mangler"
                ])
            }

            let accessToken = result.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            let authRes = try await Auth.auth().signIn(with: credential)
            return authRes.user
        }
    
    
}
