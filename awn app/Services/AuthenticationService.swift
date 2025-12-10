//
//  AuthenticationService.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  Sign in with Apple authentication service
//

import Foundation
import AuthenticationServices
import CloudKit
import Combine

class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: AppUser?
    
    private let cloudKitManager = CloudKitManager.shared
    private let userDefaults = UserDefaults.standard
    
    private init() {
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication Status
    
    func checkAuthenticationStatus() {
        guard let appleUserID = userDefaults.string(forKey: Constants.UserDefaultsKeys.appleUserID) else {
            isAuthenticated = false
            currentUser = nil
            return
        }
        
        // Verify with CloudKit
        cloudKitManager.fetchUser(byAppleUserID: appleUserID) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    NotificationCenter.default.post(name: Constants.Notifications.userDidAuthenticate, object: user)
                case .failure:
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                    self?.clearAuthenticationData()
                }
            }
        }
    }
    
    // MARK: - Sign In with Apple (Caregiver Only)
    
    func handleSignInWithApple(authorization: ASAuthorization, completion: @escaping (Result<AppUser, Error>) -> Void) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            completion(.failure(NSError(domain: "AuthenticationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])))
            return
        }
        
        let appleUserID = appleIDCredential.user
        let email = appleIDCredential.email
        let fullName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        // Check if user already exists
        cloudKitManager.fetchUser(byAppleUserID: appleUserID) { [weak self] result in
            switch result {
            case .success(let existingUser):
                // User already exists, sign in
                self?.completeAuthentication(user: existingUser)
                completion(.success(existingUser))
                
            case .failure:
                // Create new user (always caregiver)
                let newUser = AppUser(
                    appleUserID: appleUserID,
                    email: email,
                    fullName: fullName.isEmpty ? "Caregiver" : fullName
                )
                
                self?.cloudKitManager.saveUser(newUser) { saveResult in
                    switch saveResult {
                    case .success(let savedUser):
                        // Create caregiver profile
                        self?.createCaregiverProfile(for: savedUser) { profileResult in
                            switch profileResult {
                            case .success:
                                self?.completeAuthentication(user: savedUser)
                                completion(.success(savedUser))
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                        
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    private func createCaregiverProfile(for user: AppUser, completion: @escaping (Result<Void, Error>) -> Void) {
        // Create caregiver profile (no patient profile needed)
        let caregiver = Caregiver(
            userId: user.id,
            name: user.fullName ?? "Caregiver",
            relationship: "Family Member" // Default, updated during patient onboarding
        )
        
        cloudKitManager.saveCaregiver(caregiver) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func completeAuthentication(user: AppUser) {
        DispatchQueue.main.async {
            self.currentUser = user
            self.isAuthenticated = true
            
            // Save to UserDefaults (removed role field)
            self.userDefaults.set(user.appleUserID, forKey: Constants.UserDefaultsKeys.appleUserID)
            self.userDefaults.set(user.id, forKey: Constants.UserDefaultsKeys.currentUserID)
            self.userDefaults.set(true, forKey: Constants.UserDefaultsKeys.isAuthenticated)
            
            NotificationCenter.default.post(name: Constants.Notifications.userDidAuthenticate, object: user)
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.currentUser = nil
            self.clearAuthenticationData()
            NotificationCenter.default.post(name: Constants.Notifications.userDidLogout, object: nil)
        }
    }
    
    private func clearAuthenticationData() {
        userDefaults.removeObject(forKey: Constants.UserDefaultsKeys.appleUserID)
        userDefaults.removeObject(forKey: Constants.UserDefaultsKeys.currentUserID)
        userDefaults.removeObject(forKey: Constants.UserDefaultsKeys.userRole)
        userDefaults.removeObject(forKey: Constants.UserDefaultsKeys.isAuthenticated)
    }
    
    // MARK: - User Profile
    
    func getCurrentCaregiver(completion: @escaping (Result<Caregiver, Error>) -> Void) {
        guard let user = currentUser else {
            completion(.failure(NSError(domain: "AuthenticationService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])))
            return
        }
        
        cloudKitManager.fetchCaregiver(byUserID: user.id, completion: completion)
    }
}
