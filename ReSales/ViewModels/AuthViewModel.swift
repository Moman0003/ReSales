//
//  ItemRepository.swift
//  ReSales
//
//  Created by Moman Shafique on 13/12/2025.
//

import Foundation
import Combine
import FirebaseAuth
import UIKit

@MainActor
final class AuthViewModel: ObservableObject {

    @Published private(set) var currentUser: User? = nil
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false

    private let repo: AuthRepository
    private var authHandle: AuthStateDidChangeListenerHandle?
    
    var userEmail: String {
        currentUser?.email ?? ""
    }
    
    var isLoggedIn: Bool {
        currentUser != nil
    }
    
    
    init(repo: AuthRepository) {
        self.repo = repo
        self.currentUser = repo.currentUser

        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
            }
        }
    }

    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            currentUser = try await repo.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            currentUser = try await repo.signUp(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        do {
            try repo.signOut()
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func signInWithGoogle(presentingVC: UIViewController) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            currentUser = try await repo.signInWithGoogle(presentingVC: presentingVC)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    
}
