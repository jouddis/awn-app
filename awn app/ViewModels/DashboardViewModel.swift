//
//  DashboardViewModel.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  ViewModel for dashboard with 3 states support
//

import Foundation
import SwiftUI
import Combine

// MARK: - Status Enums

enum SafeZoneStatus {
    case inside
    case outside
    case unknown
    
    var displayText: String {
        switch self {
        case .inside: return "Inside safe zone"
        case .outside: return "Outside safe zone"
        case .unknown: return "Unknown"
        }
    }
    
    var color: Color {
        switch self {
        case .inside: return .green
        case .outside: return .red
        case .unknown: return .gray
        }
    }
}

enum WatchStatus {
    case connected
    case disconnected
    
    var displayText: String {
        switch self {
        case .connected: return "Connected"
        case .disconnected: return "Disconnected"
        }
    }
    
    var color: Color {
        switch self {
        case .connected: return .green
        case .disconnected: return .red
        }
    }
}

enum HealthStatus {
    case normal
    case fallDetected
    
    var displayText: String {
        switch self {
        case .normal: return "No fall detected"
        case .fallDetected: return "Needs attention! a fall is detected"
        }
    }
    
    var color: Color {
        switch self {
        case .normal: return .green
        case .fallDetected: return .red
        }
    }
}

// MARK: - Medication Model

struct TodayMedication: Identifiable {
    let id = UUID()
    let name: String
    let dosage: String
    let time: String
    let isTaken: Bool
    let icon: Image
}

// MARK: - Dashboard ViewModel

class DashboardViewModel: ObservableObject {
    // Published properties
    @Published var patientName: String = "Norah"
    @Published var currentLocation: String = "Home"
    @Published var safeZoneStatus: SafeZoneStatus = .inside
    @Published var watchStatus: WatchStatus = .connected
    @Published var healthStatus: HealthStatus = .normal
    @Published var todayMedications: [TodayMedication] = []
    @Published var isLoading: Bool = false
    
    private let cloudKitManager = CloudKitManager.shared
    private let authService = AuthenticationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Current patient
    private var currentPatient: Patient?
    
    init() {
        setupNotifications()
    }
    
    // MARK: - Setup
    
    private func setupNotifications() {
        // Listen for geofence alerts
        NotificationCenter.default.publisher(for: Constants.Notifications.geofenceExitDetected)
            .sink { [weak self] _ in
                self?.handleGeofenceExit()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Constants.Notifications.geofenceEntryDetected)
            .sink { [weak self] _ in
                self?.handleGeofenceEntry()
            }
            .store(in: &cancellables)
        
        // Listen for fall detection
        NotificationCenter.default.publisher(for: Constants.Notifications.fallDetected)
            .sink { [weak self] _ in
                self?.handleFallDetected()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load Data
    
    func loadDashboardData() {
        guard let currentUser = authService.currentUser else { return }
        
        isLoading = true
        
        // Fetch caregiver to get linked patient
        cloudKitManager.fetchCaregiver(byUserID: currentUser.id) { [weak self] result in
            switch result {
            case .success(let caregiver):
                if let patientID = caregiver.linkedPatientId {
                    self?.loadPatientData(patientID: patientID)
                }
            case .failure(let error):
                print("❌ Failed to load caregiver: \(error)")
                self?.isLoading = false
            }
        }
    }
    
    private func loadPatientData(patientID: String) {
        cloudKitManager.fetchPatient(byID: patientID) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let patient):
                    self?.isLoading = false
                    self?.currentPatient = patient
                    self?.patientName = patient.name
                    self?.loadMedications(for: patientID)
                    self?.checkSafeZoneStatus(patient: patient)
                    
                case .failure(let error):
                    print("⚠️ Failed to load patient (will retry): \(error)")
                    
                    // Retry once after 2 seconds (CloudKit might still be syncing)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self?.retryLoadPatientData(patientID: patientID)
                    }
                }
            }
        }
    }
    
    private func retryLoadPatientData(patientID: String) {
        print("🔄 Retrying patient load...")
        
        cloudKitManager.fetchPatient(byID: patientID) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let patient):
                    print("✅ Patient loaded successfully on retry")
                    self?.currentPatient = patient
                    self?.patientName = patient.name
                    self?.loadMedications(for: patientID)
                    self?.checkSafeZoneStatus(patient: patient)
                    
                case .failure(let error):
                    print("❌ Failed to load patient even after retry: \(error)")
                    // Could show error message to user here
                }
            }
        }
    }
    
    private func loadMedications(for patientID: String) {
        cloudKitManager.fetchMedications(for: patientID, activeOnly: true) { [weak self] result in
            switch result {
            case .success(let medications):
                self?.processTodayMedications(medications)
            case .failure(let error):
                print("❌ Failed to load medications: \(error)")
            }
        }
    }
    
    private func processTodayMedications(_ medications: [Medication]) {
        // For demo, create sample medications
        // In production, this would fetch actual dose logs for today
        
        let todayMeds: [TodayMedication] = [
            TodayMedication(
                name: "Panadol",
                dosage: "2 Capsule at 2:13 AM",
                time: "2:13 AM",
                isTaken: false,
                icon: Image(systemName: "capsule.fill")
            ),
            TodayMedication(
                name: "Donepezil",
                dosage: "1 Tablet at 1:07 AM",
                time: "1:07 AM",
                isTaken: true,
                icon: Image(systemName: "pill.fill")
            )
        ]
        
        DispatchQueue.main.async {
            self.todayMedications = todayMeds
        }
    }
    
    // MARK: - Safe Zone Status
    
    private func checkSafeZoneStatus(patient: Patient) {
        // In production, this would check patient's current location
        // against safe zone coordinates
        
        if patient.hasSafeZone {
            // For demo, randomly set status
            // In production, calculate from actual GPS
            safeZoneStatus = .inside
            currentLocation = "Home"
        } else {
            safeZoneStatus = .unknown
            currentLocation = "No safe zone set"
        }
    }
    
    // MARK: - Alert Handlers
    
    private func handleGeofenceExit() {
        DispatchQueue.main.async {
            self.safeZoneStatus = .outside
            self.currentLocation = "location: current coordinates"
        }
    }
    
    private func handleGeofenceEntry() {
        DispatchQueue.main.async {
            self.safeZoneStatus = .inside
            self.currentLocation = "Home"
        }
    }
    
    private func handleFallDetected() {
        DispatchQueue.main.async {
            self.healthStatus = .fallDetected
        }
    }
    
    // MARK: - Demo State Controls (for testing 3 states)
    
    func setNormalState() {
        safeZoneStatus = .inside
        currentLocation = "Home"
        watchStatus = .connected
        healthStatus = .normal
    }
    
    func setWorstCaseState() {
        safeZoneStatus = .outside
        currentLocation = "location: current coordinates"
        watchStatus = .disconnected
        healthStatus = .fallDetected
    }
    
    func setMedicationTakenState() {
        safeZoneStatus = .inside
        currentLocation = "Home"
        watchStatus = .connected
        healthStatus = .normal
        
        // Mark first medication as taken
        if !todayMedications.isEmpty {
            todayMedications[0] = TodayMedication(
                name: todayMedications[0].name,
                dosage: todayMedications[0].dosage,
                time: todayMedications[0].time,
                isTaken: true,
                icon: todayMedications[0].icon
            )
        }
    }
}

