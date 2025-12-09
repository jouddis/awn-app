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
    
    // MARK: - Sign In with Apple
    
    func handleSignInWithApple(authorization: ASAuthorization, role: UserRole, completion: @escaping (Result<AppUser, Error>) -> Void) {
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
                // Create new user
                let newUser = AppUser(
                    appleUserID: appleUserID,
                    email: email,
                    fullName: fullName.isEmpty ? "User" : fullName,
                    role: role.rawValue  // Convert enum to String
                )
                
                // Save user with proper method
                self?.cloudKitManager.saveUser(newUser) { saveResult in
                    switch saveResult {
                    case .success(let savedUser):
                        // Create corresponding Patient or Caregiver profile
                        self?.createUserProfile(for: savedUser, role: role) { profileResult in
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
    
    private func createUserProfile(for user: AppUser, role: UserRole, completion: @escaping (Result<Void, Error>) -> Void) {
        switch role {
        case .patient:
            // Create patient profile
            let patient = Patient(
                userId: user.id,
                name: user.fullName ?? "Patient"
            )
            cloudKitManager.savePatient(patient) { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            
        case .caregiver:
            // Create caregiver profile
            let caregiver = Caregiver(
                userId: user.id,
                name: user.fullName ?? "Caregiver",
                relationship: "Family Member" // Default, can be updated later
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
    }
    
    private func completeAuthentication(user: AppUser) {
        DispatchQueue.main.async {
            self.currentUser = user
            self.isAuthenticated = true
            
            // Save to UserDefaults
            self.userDefaults.set(user.appleUserID, forKey: Constants.UserDefaultsKeys.appleUserID)
            self.userDefaults.set(user.id, forKey: Constants.UserDefaultsKeys.currentUserID)
            self.userDefaults.set(user.role, forKey: Constants.UserDefaultsKeys.userRole)  // role is already String
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
    
    func getCurrentPatient(completion: @escaping (Result<Patient, Error>) -> Void) {
        guard let user = currentUser, user.role == UserRole.patient.rawValue else {
            completion(.failure(NSError(domain: "AuthenticationService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Not a patient user"])))
            return
        }
        
        cloudKitManager.fetchPatient(byID: user.id, completion: completion)
    }
    
    func getCurrentCaregiver(completion: @escaping (Result<Caregiver, Error>) -> Void) {
        guard let user = currentUser, user.role == UserRole.caregiver.rawValue else {
            completion(.failure(NSError(domain: "AuthenticationService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Not a caregiver user"])))
            return
        }
        
        cloudKitManager.fetchCaregiver(byUserID: user.id, completion: completion)
    }
}

