//
//  DashboardViewModel.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  ViewModel for dashboard with 3 states support
//

//
//  DashboardViewModel.swift
//  awn app
//
//  Updated with CloudKit alert fetching
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
    @Published var patientName: String = ""
    @Published var currentLocation: String = "Unknown"
    @Published var safeZoneStatus: SafeZoneStatus = .unknown
    @Published var watchStatus: WatchStatus = .connected
    @Published var healthStatus: HealthStatus = .normal
    @Published var todayMedications: [TodayMedication] = []
    @Published var isLoading: Bool = false
    @Published var recentAlerts: [AlertEvent] = []
    @Published var lastUpdateTime: Date = Date()
    
    private let cloudKitManager = CloudKitManager.shared
    private let authService = AuthenticationService.shared
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    // Current patient - internal for access by View
    internal var currentPatient: Patient?
    
    init() {
        setupNotifications()
        startAutoRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
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
                    
                    // NEW: Fetch latest alerts
                    self?.fetchLatestAlerts(for: patientID)
                    
                case .failure(let error):
                    print("⚠️ Failed to load patient (will retry): \(error)")
                    
                    // Retry once after 2 seconds
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
                    
                    // NEW: Fetch latest alerts
                    self?.fetchLatestAlerts(for: patientID)
                    
                case .failure(let error):
                    print("❌ Failed to load patient even after retry: \(error)")
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
    
    // MARK: - NEW: Fetch Alerts from CloudKit
    
    func fetchLatestAlerts(for patientID: String) {
        print("🔍 Fetching latest alerts for patient: \(patientID)")
        
        // Use existing CloudKitManager method
        cloudKitManager.fetchAlerts(for: patientID, unreadOnly: false) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let alerts):
                    print("✅ Fetched \(alerts.count) alerts from CloudKit")
                    
                    // Store recent alerts (last 10)
                    self?.recentAlerts = Array(alerts.prefix(10))
                    
                    // Update dashboard based on latest alert
                    if let latestAlert = alerts.first {
                        self?.updateDashboardFromAlert(latestAlert)
                    }
                    
                    self?.lastUpdateTime = Date()
                    
                case .failure(let error):
                    print("❌ Failed to fetch alerts: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Update Dashboard from Alert
    
    private func updateDashboardFromAlert(_ alert: AlertEvent) {
        print("📊 Updating dashboard from alert: \(alert.alertType)")
        
        switch alert.alertType {
        case .geofenceExit:
            safeZoneStatus = .outside
            if let lat = alert.latitude, let lon = alert.longitude {
                currentLocation = String(format: "%.4f, %.4f", lat, lon)
            } else {
                currentLocation = "Outside safe zone"
            }
            print("⚠️ Dashboard updated: Patient is OUTSIDE safe zone")
            
        case .geofenceEntry:
            safeZoneStatus = .inside
            currentLocation = "Inside safe zone"
            print("✅ Dashboard updated: Patient is INSIDE safe zone")
            
        case .fallDetected:
            healthStatus = .fallDetected
            if let lat = alert.latitude, let lon = alert.longitude {
                currentLocation = String(format: "Fall at %.4f, %.4f", lat, lon)
            }
            print("🚨 Dashboard updated: Fall detected")
        }
    }
    
    // MARK: - Auto-Refresh
    
    private func startAutoRefresh() {
        // Refresh every 30 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            guard let self = self,
                  let patientID = self.currentPatient?.id else { return }
            
            self.fetchLatestAlerts(for: patientID)
        }
    }
    
    // MARK: - Pull-to-Refresh Support
    
    @MainActor
    func refresh() async {
        guard let patientID = currentPatient?.id else { return }
        
        isLoading = true
        
        // Use async wrapper for CloudKit call
        await withCheckedContinuation { continuation in
            cloudKitManager.fetchAlerts(for: patientID, unreadOnly: false) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let alerts):
                        self?.recentAlerts = Array(alerts.prefix(10))
                        
                        if let latestAlert = alerts.first {
                            self?.updateDashboardFromAlert(latestAlert)
                        }
                        
                        self?.lastUpdateTime = Date()
                        
                    case .failure(let error):
                        print("❌ Refresh failed: \(error)")
                    }
                    
                    self?.isLoading = false
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Safe Zone Status
    
    private func checkSafeZoneStatus(patient: Patient) {
        if patient.hasSafeZone {
            // Will be updated by fetchLatestAlerts
            safeZoneStatus = .unknown
            currentLocation = "Loading..."
        } else {
            safeZoneStatus = .unknown
            currentLocation = "No safe zone set"
        }
    }
    
    // MARK: - Alert Handlers (from NotificationCenter)
    
    private func handleGeofenceExit() {
        DispatchQueue.main.async {
            self.safeZoneStatus = .outside
            self.currentLocation = "Outside safe zone"
        }
        
        // Refresh alerts to get the new one
        if let patientID = currentPatient?.id {
            fetchLatestAlerts(for: patientID)
        }
    }
    
    private func handleGeofenceEntry() {
        DispatchQueue.main.async {
            self.safeZoneStatus = .inside
            self.currentLocation = "Inside safe zone"
        }
        
        // Refresh alerts
        if let patientID = currentPatient?.id {
            fetchLatestAlerts(for: patientID)
        }
    }
    
    private func handleFallDetected() {
        DispatchQueue.main.async {
            self.healthStatus = .fallDetected
        }
        
        // Refresh alerts
        if let patientID = currentPatient?.id {
            fetchLatestAlerts(for: patientID)
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
