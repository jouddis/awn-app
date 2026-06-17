//
//  AuthenticationViewModel.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  ViewModel for authentication flow - Caregiver only
//  Updated with demo mode for Apple Review
//
//
//  AuthenticationViewModel.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  ViewModel for authentication flow - Caregiver only
//  Updated with demo mode for Apple Review
//
//
//  AuthenticationViewModel.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//  Updated: Added "Skip for now" guest mode
//

import Foundation
import AuthenticationServices
import Combine

class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isGuest: Bool = false
    @Published var selectedRole: UserRole? = nil      // set after role picker
    @Published var hasCompletedOnboarding: Bool = false
    @Published var isLoading: Bool = true
    @Published var currentUser: AppUser?
    @Published var errorMessage: String?

    // Computed: user can access app if signed in OR skipped
    var isActive: Bool { isAuthenticated || isGuest }

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

        // Restore role from previous session
        if let roleRaw = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.selectedRole),
           let role = UserRole(rawValue: roleRaw) {
            selectedRole = role
        }
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)

        // Check if user previously tapped "Skip for now"
        if UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.isGuestUser) {
            isGuest = true
            isLoading = false
            return
        }

        authService.checkAuthenticationStatus()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
        }
    }

    // MARK: - Sign In with Apple

    func handleSignInWithApple(authorization: ASAuthorization) {
        isLoading = true
        errorMessage = nil

        authService.handleSignInWithApple(authorization: authorization) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false

                switch result {
                case .success(let user):
                    // Clear guest mode if they were a guest before
                    UserDefaults.standard.set(false, forKey: Constants.UserDefaultsKeys.isGuestUser)
                    self?.isGuest = false
                    print("✅ Successfully signed in: \(user.fullName ?? "User") as caregiver")

                case .failure(let error):
                    self?.errorMessage = "Sign in failed: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Skip for now (Guest Mode) ← NEW

    func skipSignIn() {
        print("👤 User skipped sign in - entering guest mode")
        UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.isGuestUser)
        isGuest = true
    }

    // MARK: - Role Selection

    func setRole(_ role: UserRole) {
        selectedRole = role
        UserDefaults.standard.set(role.rawValue, forKey: Constants.UserDefaultsKeys.selectedRole)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)
    }

    // MARK: - Sign Out

    func signOut() {
        UserDefaults.standard.set(false, forKey: Constants.UserDefaultsKeys.isGuestUser)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.selectedRole)
        UserDefaults.standard.set(false, forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)
        isGuest = false
        selectedRole = nil
        hasCompletedOnboarding = false
        authService.signOut()
        errorMessage = nil
    }

    // MARK: - Demo Mode (For Apple Review ONLY)

    func loginAsDemoUser() {
        print("🎭 Logging in as DEMO user for Apple Review")

        isLoading = true

        let demoUser = AppUser(
            id: "DEMO-USER-12345",
            appleUserID: "demo.account.review",
            email: "demo@awnapp.com",
            fullName: "Demo Caregiver",
            createdAt: Date(),
            updatedAt: Date()
        )

        cloudKitManager.saveUser(demoUser) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Demo user saved to CloudKit")
                case .failure(let error):
                    print("⚠️ Demo user CloudKit save failed (non-critical): \(error)")
                }

                self?.authService.currentUser = demoUser
                self?.currentUser = demoUser
                self?.isAuthenticated = true
                self?.isLoading = false

                self?.createDemoData(for: demoUser)

                print("✅ Demo user logged in successfully")
            }
        }
    }

    private func createDemoData(for demoUser: AppUser) {
        print("🎭 Creating demo data for Apple Review...")

        let demoCaregiver = Caregiver(
            id: "DEMO-CAREGIVER-12345",
            userId: demoUser.id,
            name: demoUser.fullName ?? "Demo Caregiver",
            relationship: "Family Member",
            linkedPatientId: "DEMO-PATIENT-12345",
            createdAt: Date(),
            updatedAt: Date()
        )

        let demoPatient = Patient(
            id: "DEMO-PATIENT-12345",
            name: "Mohammed Ali",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -75, to: Date()) ?? Date(),
            caregiverId: "DEMO-CAREGIVER-12345",
            safeZoneName: "Home",
            safeZoneCenterLat: 24.7136,
            safeZoneCenterLon: 46.6753,
            safeZoneRadius: 250.0,
            safeZoneIsActive: true,
            safeZoneCreatedAt: Date(),
            safeZoneUpdatedAt: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )

        cloudKitManager.saveCaregiver(demoCaregiver) { result in
            switch result {
            case .success: print("✅ Demo caregiver saved")
            case .failure(let error): print("⚠️ Demo caregiver save failed: \(error)")
            }
        }

        cloudKitManager.savePatient(demoPatient) { result in
            switch result {
            case .success:
                print("✅ Demo patient saved with safe zone")
                self.createDemoAlerts(for: demoPatient)
            case .failure(let error):
                print("⚠️ Demo patient save failed: \(error)")
            }
        }
    }

    private func createDemoAlerts(for patient: Patient) {
        let fallCreatedAt = Date().addingTimeInterval(-3600)
        let fallAlert = AlertEvent(
            patientId: patient.id,
            alertType: .fallDetected,
            timestamp: fallCreatedAt,
            latitude: 24.7136,
            longitude: 46.6753,
            isRead: false,
            createdAt: fallCreatedAt
        )

        let geoCreatedAt = Date().addingTimeInterval(-7200)
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

        cloudKitManager.saveAlertEvent(fallAlert) { result in
            if case .success = result { print("✅ Demo fall alert created") }
        }

        cloudKitManager.saveAlertEvent(geofenceAlert) { result in
            if case .success = result { print("✅ Demo geofence alert created") }
        }
    }
}
