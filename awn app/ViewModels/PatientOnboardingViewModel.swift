//
//  PatientOnboardingViewModel.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  ViewModel for patient onboarding flow
//

import Foundation
import Combine

enum OnboardingStep {
    case firstName
    case relationship
    case customRelationship
    case review
    case watchPairingInfo
    case watchPairingVisual
    case completed
}

class PatientOnboardingViewModel: ObservableObject {
    // Published properties
    @Published var currentStep: OnboardingStep = .firstName
    @Published var firstName: String = ""
    @Published var relationship: String = ""
    @Published var customRelationship: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let cloudKitManager = CloudKitManager.shared
    private let authService = AuthenticationService.shared
    
    // Computed property for display
    var displayRelationship: String {
        if relationship == "Other" {
            return customRelationship
        }
        return relationship
    }
    
    // MARK: - Navigation
    
    func moveToNextStep() {
        switch currentStep {
        case .firstName:
            currentStep = .relationship
            
        case .relationship:
            if relationship == "Other" {
                currentStep = .customRelationship
            } else {
                currentStep = .review
            }
            
        case .customRelationship:
            currentStep = .review
            
        case .review:
            currentStep = .watchPairingInfo
            
        case .watchPairingInfo:
            currentStep = .watchPairingVisual
            
        case .watchPairingVisual:
            currentStep = .completed
            
        case .completed:
            break
        }
    }
    
    func selectRelationship(_ relation: String) {
        relationship = relation
        // User must tap Next button - no auto-advance
    }
    
    // MARK: - Complete Onboarding
    
    func completeOnboarding() {
        guard let currentUser = authService.currentUser else {
            errorMessage = "No authenticated user"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Create patient profile - Let Patient generate its own UUID
        let patient = Patient(
            // DON'T pass id - let it generate new UUID
            userId: currentUser.id,
            name: firstName,
            dateOfBirth: nil,
            caregiverId: currentUser.id
        )
        
        cloudKitManager.savePatient(patient) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let savedPatient):
                    print("✅ Patient created: \(savedPatient.name)")
                    
                    // Update caregiver with linked patient
                    self?.linkPatientToCaregiver(patientID: savedPatient.id, caregiverUserID: currentUser.id)
                    
                case .failure(let error):
                    self?.errorMessage = "Failed to create patient: \(error.localizedDescription)"
                    print("❌ Error: \(error)")
                }
            }
        }
    }
    
    private func linkPatientToCaregiver(patientID: String, caregiverUserID: String) {
        // Fetch caregiver and update with patient ID
        cloudKitManager.fetchCaregiver(byUserID: caregiverUserID) { [weak self] result in
            switch result {
            case .success(var caregiver):
                caregiver.linkedPatientId = patientID
                
                self?.cloudKitManager.saveCaregiver(caregiver) { saveResult in
                    switch saveResult {
                    case .success:
                        print("✅ Caregiver linked to patient")
                        
                        // Verify patient is fetchable before navigating to dashboard
                        DispatchQueue.main.async {
                            self?.currentStep = .completed
                            self?.verifyPatientAndNavigate(patientID: patientID)
                        }
                        
                    case .failure(let error):
                        print("❌ Failed to link caregiver: \(error)")
                    }
                }
                
            case .failure(let error):
                print("❌ Failed to fetch caregiver: \(error)")
            }
        }
    }
    
    private func verifyPatientAndNavigate(patientID: String) {
        print("🔄 Verifying patient is fetchable...")
        
        // Try to fetch the patient to confirm it's accessible
        cloudKitManager.fetchPatient(byID: patientID) { [weak self] result in
            switch result {
            case .success(let patient):
                // Patient found! Navigate to dashboard
                print("✅ Patient verified: \(patient.name)")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("OnboardingCompleted"),
                        object: nil
                    )
                }
                
            case .failure(let error):
                // Patient not found yet, retry after delay
                print("⚠️ Patient not found yet, retrying... (\(error.localizedDescription))")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.verifyPatientAndNavigate(patientID: patientID)
                }
            }
        }
    }
}

