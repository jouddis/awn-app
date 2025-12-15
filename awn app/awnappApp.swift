//
//  awn_appApp.swift
//  awn app
//
//  Created by Joud Almashgari on 01/12/2025.
//

//
//  awn_appApp.swift
//  awn app
//
//  Created by Joud Almashgari on 01/12/2025.
//
//  Main app entry point with animated splash screen
//

import SwiftUI
import CloudKit

@main
struct AwnApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthenticationViewModel()
    @State private var showSplash = true  // ← Added for splash screen
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main app content
                ContentView()
                    .environmentObject(authViewModel)
                
                // Animated splash screen overlay
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(999)  // Keep splash on top
                }
            }
            .onAppear {
                // Hide splash after 2.5 seconds with fade animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeOut(duration: 0.8)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        Group {
            if authViewModel.isLoading {
                LoadingView()
            } else if authViewModel.isAuthenticated {
                // Only caregiver flow - no patient login
                CaregiverFlowView()
            } else {
                AuthenticationView()
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black  // Match splash screen background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Aoun")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Caregiver Flow (Decides: Onboarding or Dashboard)

struct CaregiverFlowView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var hasPatient: Bool = false
    @State private var isCheckingPatient: Bool = true
    
    var body: some View {
        Group {
            if isCheckingPatient {
                LoadingView()
            } else if hasPatient {
                // Has patient → Show Main Tabs
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                // No patient → Show Onboarding
                PatientOnboardingView()
            }
        }
        .onAppear {
            checkForPatient()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OnboardingCompleted"))) { _ in
            // When onboarding completes, show dashboard
            hasPatient = true
        }
    }
    
    private func checkForPatient() {
        guard let user = authViewModel.currentUser else {
            isCheckingPatient = false
            return
        }
        
        // Check if caregiver has a linked patient
        CloudKitManager.shared.fetchCaregiver(byUserID: user.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let caregiver):
                    if let patientID = caregiver.linkedPatientId {
                        // Has patient ID - verify patient exists
                        self.verifyPatientExists(patientID: patientID)
                    } else {
                        // No patient linked
                        self.isCheckingPatient = false
                        self.hasPatient = false
                    }
                case .failure(let error):
                    print("❌ Error checking for patient: \(error)")
                    self.isCheckingPatient = false
                    self.hasPatient = false
                }
            }
        }
    }
    
    private func verifyPatientExists(patientID: String) {
        CloudKitManager.shared.fetchPatient(byID: patientID) { result in
            DispatchQueue.main.async {
                self.isCheckingPatient = false
                
                switch result {
                case .success:
                    // Patient exists
                    self.hasPatient = true
                case .failure(let error):
                    // Patient record not found (deleted or error)
                    print("⚠️ Patient record not found: \(error)")
                    self.hasPatient = false
                }
            }
        }
    }
}
