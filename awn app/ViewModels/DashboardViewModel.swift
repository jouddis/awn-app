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
//  Updated with dynamic UI states and notification panel logic
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
    // MARK: - Published Properties
    
    @Published var patientName: String = ""
    @Published var currentLocation: String = "Unknown"
    @Published var safeZoneStatus: SafeZoneStatus = .unknown
    @Published var watchStatus: WatchStatus = .connected
    @Published var healthStatus: HealthStatus = .normal
    @Published var todayMedications: [TodayMedication] = []
    @Published var isLoading: Bool = false
    @Published var recentAlerts: [AlertEvent] = []
    @Published var lastUpdateTime: Date = Date()
    
    // NEW: Dynamic UI State Properties
    @Published var hasLocation: Bool = false
    @Published var hasMedication: Bool = false
    @Published var hasUnreadAlerts: Bool = false
    @Published var hasPatient: Bool = false
    
    // MARK: - Private Properties
    
    private let cloudKitManager = CloudKitManager.shared
    private let authService = AuthenticationService.shared
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    private var lastReadAlertsTimestamp: Date?
    
    // Current patient - internal for access by View
    internal var currentPatient: Patient?
    
    // MARK: - Initialization
    
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
    
    // MARK: - Load Dashboard Data
    
    func loadDashboardData() {
        guard let currentUser = authService.currentUser else {
            print("❌ No authenticated user")
            resetToEmptyState()
            return
        }
        
        isLoading = true
        
        // Fetch caregiver to get linked patient
        cloudKitManager.fetchCaregiver(byUserID: currentUser.id) { [weak self] result in
            switch result {
            case .success(let caregiver):
                if let patientID = caregiver.linkedPatientId {
                    self?.loadPatientData(patientID: patientID)
                } else {
                    DispatchQueue.main.async {
                        self?.resetToEmptyState()
                    }
                }
                
            case .failure(let error):
                print("❌ Failed to load caregiver: \(error)")
                DispatchQueue.main.async {
                    self?.resetToEmptyState()
                }
            }
        }
    }
    
    // MARK: - Load Patient Data
    
    private func loadPatientData(patientID: String) {
        cloudKitManager.fetchPatient(byID: patientID) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let patient):
                    self?.isLoading = false
                    self?.currentPatient = patient
                    self?.patientName = patient.name
                    self?.hasPatient = true
                    
                    // CHECK IF LOCATION EXISTS
                    self?.hasLocation = patient.hasSafeZone
                    
                    print("✅ Patient loaded: \(patient.name)")
                    print("   Has safe zone: \(patient.hasSafeZone)")
                    
                    // Load related data
                    self?.loadMedications(for: patientID)
                    self?.checkSafeZoneStatus(patient: patient)
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
                    self?.hasPatient = true
                    self?.hasLocation = patient.hasSafeZone
                    
                    self?.loadMedications(for: patientID)
                    self?.checkSafeZoneStatus(patient: patient)
                    self?.fetchLatestAlerts(for: patientID)
                    
                case .failure(let error):
                    print("❌ Failed to load patient even after retry: \(error)")
                    self?.resetToEmptyState()
                }
            }
        }
    }
    
    // MARK: - Load Medications
    
    private func loadMedications(for patientID: String) {
        cloudKitManager.fetchMedications(for: patientID, activeOnly: true) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let medications):
                    print("✅ Loaded \(medications.count) medications")
                    
                    // CHECK IF MEDICATION EXISTS
                    self?.hasMedication = !medications.isEmpty
                    
                    // Process today's medications
                    self?.processTodayMedications(medications)
                    
                case .failure(let error):
                    print("❌ Failed to load medications: \(error)")
                    self?.hasMedication = false
                    self?.todayMedications = []
                }
            }
        }
    }
    
    private func processTodayMedications(_ medications: [Medication]) {
        // Filter medications that have doses scheduled for today
        // For now, using mock data - replace with actual dose log checking
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
        
        // Only show if there are today's medications
        self.todayMedications = todayMeds
    }
    
    // MARK: - Fetch Latest Alerts
    
    func fetchLatestAlerts(for patientID: String) {
        print("🔍 Fetching latest alerts for patient: \(patientID)")
        
        cloudKitManager.fetchAlerts(for: patientID, unreadOnly: false) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let alerts):
                    print("✅ Fetched \(alerts.count) alerts from CloudKit")
                    
                    // Sort by timestamp (most recent first)
                    let sortedAlerts = alerts.sorted { $0.timestamp > $1.timestamp }
                    self?.recentAlerts = sortedAlerts
                    
                    // Check if there are new unread alerts
                    self?.checkForNewAlerts()
                    
                    // Update dashboard based on latest alert
                    if let latestAlert = sortedAlerts.first {
                        self?.updateDashboardFromAlert(latestAlert)
                    }
                    
                    self?.lastUpdateTime = Date()
                    
                case .failure(let error):
                    print("❌ Failed to fetch alerts: \(error.localizedDescription)")
                    self?.recentAlerts = []
                    self?.hasUnreadAlerts = false
                }
            }
        }
    }
    
    // MARK: - Check for New Alerts
    
    private func checkForNewAlerts() {
        guard let lastRead = lastReadAlertsTimestamp else {
            // First time - if there are alerts, mark as unread
            hasUnreadAlerts = !recentAlerts.isEmpty
            if hasUnreadAlerts {
                print("🔴 \(recentAlerts.count) unread alerts (first load)")
            }
            return
        }
        
        // Check if there are any alerts newer than last read time
        let newAlerts = recentAlerts.filter { $0.timestamp > lastRead }
        hasUnreadAlerts = !newAlerts.isEmpty
        
        if hasUnreadAlerts {
            print("🔴 \(newAlerts.count) new unread alerts")
        }
    }
    
    // MARK: - Mark Alerts as Read
    
    func markAlertsAsRead() {
        lastReadAlertsTimestamp = Date()
        hasUnreadAlerts = false
        print("✅ Alerts marked as read at \(Date())")
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
        
        // Reload patient data to check if location/medication added
        await withCheckedContinuation { continuation in
            cloudKitManager.fetchPatient(byID: patientID) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let patient):
                        self?.currentPatient = patient
                        self?.hasLocation = patient.hasSafeZone
                        
                        // Reload medications
                        self?.loadMedications(for: patientID)
                        
                        // Fetch alerts
                        self?.fetchLatestAlerts(for: patientID)
                        
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
    
    // MARK: - Reset to Empty State
    
    private func resetToEmptyState() {
        isLoading = false
        hasPatient = false
        hasLocation = false
        hasMedication = false
        hasUnreadAlerts = false
        currentPatient = nil
        patientName = ""
        recentAlerts = []
        todayMedications = []
        print("🔄 Dashboard reset to empty state")
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
