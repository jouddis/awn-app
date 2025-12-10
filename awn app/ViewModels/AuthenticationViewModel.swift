//
//  AuthenticationViewModel.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  ViewModel for authentication flow - Caregiver only
//

import Foundation
import AuthenticationServices
import Combine

class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = true
    @Published var currentUser: AppUser?
    @Published var errorMessage: String?
    
    private let authService = AuthenticationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        checkAuthentication()
    }
    
    private func setupBindings() {
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: &$isAuthenticated)
        
        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentUser)
    }
    
    func checkAuthentication() {
        isLoading = true
        authService.checkAuthenticationStatus()
        
        // Small delay to show loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
        }
    }
    
    // MARK: - Sign In (Caregiver Only)
    
    func handleSignInWithApple(authorization: ASAuthorization) {
        isLoading = true
        errorMessage = nil
        
        // Always sign in as caregiver
        authService.handleSignInWithApple(authorization: authorization) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let user):
                    print("✅ Successfully signed in: \(user.fullName ?? "User") as caregiver")
                    
                case .failure(let error):
                    self?.errorMessage = "Sign in failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        authService.signOut()
        errorMessage = nil
    }
}

