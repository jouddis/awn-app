//
//  Untitled.swift
//  awn app
//
//  Created by Joud Almashgari on 11/12/2025.
//
//
//  WatchViewModel.swift (Simplified Version)
//  Awn Watch App
//
//  ViewModel for watch app - monitoring status only
//  Alerts are created and sent to caregiver, not displayed on watch
//
//  WatchViewModel.swift (Simplified Version)
//  Awn Watch App
//
//  ViewModel for watch app - monitoring status only
//  Alerts are created and sent to caregiver, not displayed on watch
//
//
//  WatchViewModel.swift (Simplified Version)
//  Awn Watch App
//
//  ViewModel for watch app - monitoring status only
//  Alerts are created and sent to caregiver, not displayed on watch
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

class WatchViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isLoading: Bool = true
    @Published var currentPatient: Patient?
    
    // Monitoring status
    @Published var isFallMonitoring: Bool = false
    @Published var isGeofenceMonitoring: Bool = false
    @Published var isInsideSafeZone: Bool = true
    @Published var lastKnownLocation: CLLocation?
    @Published var monitoringMode: GeofenceService.MonitoringMode = .lowPower
    
    // MARK: - Private Properties
    
    private let cloudKitManager = WatchCloudKitManager.shared
    private let fallDetectionService = FallDetectionService.shared
    private let geofenceService = GeofenceService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    // Patient ID will come from Family Setup pairing
    private var patientID: String?
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
        
        // 🧪 DEBUG: Set patient ID for testing
        // Remove this in production - should come from iOS app via Watch Connectivity
        #if DEBUG
        UserDefaults.standard.set("E41B8C79-3CAF-4ABC-A346-AC21ADAC5825", forKey: "currentPatientID")
        print("🧪 DEBUG: Set test patient ID")
        #endif
        
        // Note: Alerts are NOT displayed on watch
        // They are created by services and sent to caregiver's iPhone via CloudKit
    }
    
    // MARK: - Public Methods
    
    func initialize() {
        fetchCurrentPatient()
    }
    
    func refreshData() {
        fetchCurrentPatient()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Bind fall detection service
        fallDetectionService.$isMonitoring
            .receive(on: DispatchQueue.main)
            .assign(to: &$isFallMonitoring)
        
        // Bind geofence service
        geofenceService.$isMonitoring
            .receive(on: DispatchQueue.main)
            .assign(to: &$isGeofenceMonitoring)
        
        geofenceService.$isInsideSafeZone
            .receive(on: DispatchQueue.main)
            .assign(to: &$isInsideSafeZone)
        
        geofenceService.$lastKnownLocation
            .receive(on: DispatchQueue.main)
            .assign(to: &$lastKnownLocation)
        
        geofenceService.$currentMode
            .receive(on: DispatchQueue.main)
            .assign(to: &$monitoringMode)
    }
    
    private func fetchCurrentPatient() {
        print("📱 [WatchViewModel] fetchCurrentPatient called")
        isLoading = true
        
        // In a real implementation, get patient ID from:
        // 1. Family Setup pairing info
        // 2. CloudKit subscription
        // 3. UserDefaults cache
        
        // For now, query for the patient record associated with this watch
        fetchPairedPatient()
    }
    
    private func fetchPairedPatient() {
        // Placeholder: Get from UserDefaults if previously cached
        if let cachedPatientID = UserDefaults.standard.string(forKey: "currentPatientID") {
            print("✅ Found cached patient ID: \(cachedPatientID)")
            fetchPatient(byID: cachedPatientID)
        } else {
            print("❌ No patient ID found in UserDefaults")
            // No patient found - setup required
            DispatchQueue.main.async {
                self.isLoading = false
                self.currentPatient = nil
                print("⚠️ Showing 'Setup Required' screen")
            }
        }
    }
    
    private func fetchPatient(byID id: String) {
        print("🔍 [WatchViewModel] Fetching patient from CloudKit: \(id)")
        
        // 🧪 DEBUG: Use mock patient if CloudKit fails
        #if DEBUG
        // Create mock patient for testing
        let mockPatient = Patient(
            id: id,
            name: "Ahmed Ali",
            dateOfBirth: Date(),
            caregiverId: "caregiver123",
            watchDeviceID: nil,
            watchSerialNumber: nil,
            watchPairedDate: nil,
            safeZoneName: "Home",
            safeZoneCenterLat: 24.7136,
            safeZoneCenterLon: 46.6753,
            safeZoneRadius: 500.0,
            safeZoneIsActive: true
        )
        
        // Try CloudKit first, fallback to mock if fails
        cloudKitManager.fetchPatient(byID: id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let patient):
                    print("✅ [WatchViewModel] Patient fetched from CloudKit: \(patient.name)")
                    self?.currentPatient = patient
                    self?.patientID = patient.id
                    
                    // Cache patient ID
                    UserDefaults.standard.set(patient.id, forKey: "currentPatientID")
                    
                    // Start monitoring services
                    self?.startMonitoring(for: patient.id)
                    
                    print("✅ Patient loaded: \(patient.name)")
                    print("📍 Monitoring started for patient: \(patient.id)")
                    
                case .failure(let error):
                    print("❌ [WatchViewModel] CloudKit fetch failed: \(error.localizedDescription)")
                    print("🧪 [WatchViewModel] Using MOCK patient for testing")
                    
                    // Use mock patient for testing
                    self?.currentPatient = mockPatient
                    self?.patientID = mockPatient.id
                    
                    // Start monitoring services
                    self?.startMonitoring(for: mockPatient.id)
                    
                    print("✅ Mock patient loaded: \(mockPatient.name)")
                    print("📍 Monitoring started with mock data")
                }
            }
        }
        #else
        // Production: Only use CloudKit
        cloudKitManager.fetchPatient(byID: id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let patient):
                    print("✅ [WatchViewModel] Patient fetched successfully: \(patient.name)")
                    self?.currentPatient = patient
                    self?.patientID = patient.id
                    
                    // Cache patient ID
                    UserDefaults.standard.set(patient.id, forKey: "currentPatientID")
                    
                    // Start monitoring services
                    self?.startMonitoring(for: patient.id)
                    
                    print("✅ Patient loaded: \(patient.name)")
                    print("📍 Monitoring started for patient: \(patient.id)")
                    
                case .failure(let error):
                    print("❌ [WatchViewModel] Failed to fetch patient: \(error)")
                    print("❌ Error details: \(error.localizedDescription)")
                }
            }
        }
        #endif
    }
    
    private func startMonitoring(for patientID: String) {
        // Start fall detection
        fallDetectionService.startMonitoring(for: patientID)
        
        // Start geofence monitoring
        geofenceService.startMonitoring(for: patientID)
        
        print("🎯 All monitoring services started")
        print("   - Fall detection: Active")
        print("   - Geofence monitoring: Active")
        print("   - Alerts will be sent to caregiver's iPhone")
    }
}

// MARK: - Patient Configuration Helper

extension WatchViewModel {
    
    /// Call this method when the watch is first paired with a patient
    /// This should be triggered by the iOS app sending the patient ID
    func configureForPatient(id: String) {
        UserDefaults.standard.set(id, forKey: "currentPatientID")
        fetchPatient(byID: id)
    }
    
    /// Clear patient configuration (for testing or when unpairing)
    func clearPatientConfiguration() {
        UserDefaults.standard.removeObject(forKey: "currentPatientID")
        
        fallDetectionService.stopMonitoring()
        geofenceService.stopMonitoring()
        
        DispatchQueue.main.async {
            self.currentPatient = nil
            self.isFallMonitoring = false
            self.isGeofenceMonitoring = false
        }
    }
}

