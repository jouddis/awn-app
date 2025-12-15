//
//  AuthenticationViewModel.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  ViewModel for authentication flow - Caregiver only
//  Updated with demo mode for Apple Review
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
    private let cloudKitManager = CloudKitManager.shared
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
    
    // MARK: - Demo Mode (For Apple Review ONLY)
    
    func loginAsDemoUser() {
        print("🎭 Logging in as DEMO user for Apple Review")
        
        isLoading = true
        
        // Create demo user
        let demoUser = AppUser(
            id: "DEMO-USER-12345",
            appleUserID: "demo.account.review",
            email: "demo@awnapp.com",
            fullName: "Demo Caregiver",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Save demo user to CloudKit (optional, for persistence)
        cloudKitManager.saveUser(demoUser) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Demo user saved to CloudKit")
                case .failure(let error):
                    print("⚠️ Demo user CloudKit save failed (non-critical): \(error)")
                }
                
                // Set as current user regardless of CloudKit success
                self?.authService.currentUser = demoUser
                self?.currentUser = demoUser
                self?.isAuthenticated = true
                self?.isLoading = false
                
                // Create demo patient and caregiver data
                self?.createDemoData(for: demoUser)
                
                print("✅ Demo user logged in successfully")
            }
        }
    }
    
    private func createDemoData(for demoUser: AppUser) {
        print("🎭 Creating demo data for Apple Review...")
        
        // Create demo caregiver
        let demoCaregiver = Caregiver(
            id: "DEMO-CAREGIVER-12345",
            userId: demoUser.id,
            name: demoUser.fullName ?? "Demo Caregiver",
            relationship: "Family Member",
            linkedPatientId: "DEMO-PATIENT-12345",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Create demo patient with sample data
        let demoPatient = Patient(
            id: "DEMO-PATIENT-12345",
            name: "Mohammed Ali",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -75, to: Date()) ?? Date(),
            caregiverId: "DEMO-CAREGIVER-12345",
            safeZoneName: "Home",
            safeZoneCenterLat: 24.7136,  // Riyadh coordinates
            safeZoneCenterLon: 46.6753,
            safeZoneRadius: 250.0,
            safeZoneIsActive: true,
            safeZoneCreatedAt: Date(),
            safeZoneUpdatedAt: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Save demo caregiver
        cloudKitManager.saveCaregiver(demoCaregiver) { result in
            switch result {
            case .success:
                print("✅ Demo caregiver saved")
            case .failure(let error):
                print("⚠️ Demo caregiver save failed: \(error)")
            }
        }
        
        // Save demo patient
        cloudKitManager.savePatient(demoPatient) { result in
            switch result {
            case .success:
                print("✅ Demo patient saved with safe zone")
                
                // Optionally create demo alerts
                self.createDemoAlerts(for: demoPatient)
                
            case .failure(let error):
                print("⚠️ Demo patient save failed: \(error)")
            }
        }
    }
    
    private func createDemoAlerts(for patient: Patient) {
        // Create a sample fall detection alert
        let fallCreatedAt = Date().addingTimeInterval(-3600) // 1 hour ago
        let fallAlert = AlertEvent(
            patientId: patient.id,
            alertType: .fallDetected,
            timestamp: fallCreatedAt,
            latitude: 24.7136,
            longitude: 46.6753,
            isRead: false,
            createdAt: fallCreatedAt
        )
        
        // Create a sample geofence exit alert
        let geoCreatedAt = Date().addingTimeInterval(-7200) // 2 hours ago
        let geofenceAlert = AlertEvent(
            patientId: patient.id,
            alertType: .geofenceExit,
            timestamp: geoCreatedAt,
            latitude: 24.7200,
            longitude: 46.6800,
            isRead: true,
            confirmationStatus: .wandering,
            createdAt: geoCreatedAt
        )
        
        // Save demo alerts
        cloudKitManager.saveAlertEvent(fallAlert) { result in
            if case .success = result {
                print("✅ Demo fall alert created")
            }
        }
        
        cloudKitManager.saveAlertEvent(geofenceAlert) { result in
            if case .success = result {
                print("✅ Demo geofence alert created")
            }
        }
    }
}
