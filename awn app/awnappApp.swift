//
//  awn_appApp.swift
//  awn app
//
//  Created by Joud Almashgari on 01/12/2025.
//

//
//  awnappApp.swift
//  awn app
//

import SwiftUI
import CloudKit

@main
struct AwnApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthenticationViewModel()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environmentObject(authViewModel)

                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(999)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeOut(duration: 0.8)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}

// MARK: - Root Router
//
// States:
//  loading          → spinner
//  guest            → full app browse (read-only), "Create Profile" in settings
//  signed in,
//    no role        → RoleSelectionView
//    role set,
//      no onboarding → role-specific onboarding
//      onboarding done → MainTabView

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    var body: some View {
        Group {
            if authViewModel.isLoading {
                LoadingView()

            } else if authViewModel.isGuest {
                // Browse mode — full app visible, sign-in prompt in settings
                GuestAppView()

            } else if authViewModel.isAuthenticated {
                if authViewModel.selectedRole == nil {
                    // Step 1: pick role
                    RoleSelectionView()
                } else if !authViewModel.hasCompletedOnboarding {
                    // Step 2: role-specific onboarding
                    OnboardingRouterView()
                } else {
                    // Step 3: full app — route by role
                    if authViewModel.selectedRole == .patient {
                        PatientMainView()
                    } else {
                        MainTabView()
                    }
                }
            } else {
                // Not signed in, not guest → landing
                AuthenticationView()
            }
        }
    }
}

// MARK: - Onboarding Router
// Picks the right onboarding flow based on role

struct OnboardingRouterView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    var body: some View {
        Group {
            switch authViewModel.selectedRole {
            case .caregiver:
                CaregiverOnboardingFlowView()
            case .patient:
                PatientSelfOnboardingView()
            case .none:
                LoadingView()
            }
        }
    }
}

// MARK: - Caregiver Onboarding Flow
// Wraps the existing CaregiverFlowView logic (check for existing patient or start onboarding)

struct CaregiverOnboardingFlowView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var hasPatient: Bool = false
    @State private var isChecking: Bool = true

    var body: some View {
        Group {
            if isChecking {
                LoadingView()
            } else if hasPatient {
                // Already has a patient — mark done and go to app
                Color.clear.onAppear {
                    authViewModel.completeOnboarding()
                }
            } else {
                PatientOnboardingView()
            }
        }
        .onAppear { checkForPatient() }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OnboardingCompleted"))) { _ in
            authViewModel.completeOnboarding()
        }
    }

    private func checkForPatient() {
        guard let user = authViewModel.currentUser else {
            isChecking = false; return
        }
        CloudKitManager.shared.fetchCaregiver(byUserID: user.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let caregiver):
                    if let patientID = caregiver.linkedPatientId {
                        self.verifyPatient(patientID)
                    } else {
                        self.isChecking = false
                        self.hasPatient = false
                    }
                case .failure:
                    self.isChecking = false
                    self.hasPatient = false
                }
            }
        }
    }

    private func verifyPatient(_ id: String) {
        CloudKitManager.shared.fetchPatient(byID: id) { result in
            DispatchQueue.main.async {
                self.isChecking = false
                self.hasPatient = (try? result.get()) != nil
            }
        }
    }
}

// MARK: - Guest App View
// Full app browse with a banner/button to sign up

struct GuestAppView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showSignInSheet = false

    var body: some View {
        ZStack(alignment: .top) {
            MainTabView()
                .onAppear { DemoSession.shared.activate() }

            // Subtle top banner
            if showSignInSheet == false {
                GuestBanner(onSignIn: { showSignInSheet = true })
                    .zIndex(10)
            }
        }
        .sheet(isPresented: $showSignInSheet) {
            AuthenticationView()
                .environmentObject(authViewModel)
        }
    }
}

struct GuestBanner: View {
    let onSignIn: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .foregroundColor(Color(hex: "6C7CD1"))
            Text("Browsing as guest")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Button("Sign In", action: onSignIn)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "6C7CD1"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "1C1C1E").opacity(0.97))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(.white.opacity(0.1)),
            alignment: .bottom
        )
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                Text("Awn")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
    }
}
