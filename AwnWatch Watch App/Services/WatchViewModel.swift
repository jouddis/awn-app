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
//  WatchViewModel.swift
//  awn app Watch App
//
//  Updated to use fetchCurrentPatient() - no more cached ID issues!
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

class WatchViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentPatient: Patient?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Exposed monitoring state for UI
    @Published var isFallMonitoring: Bool = false
    @Published var isGeofenceMonitoring: Bool = false
    @Published var isInsideSafeZone: Bool = false
    @Published var monitoringMode: GeofenceService.MonitoringMode = .highPower
    @Published var lastKnownLocation: CLLocation?
    
    // MARK: - Services
    
    private let cloudKitManager = WatchCloudKitManager.shared
    private let geofenceService = GeofenceService.shared
    private let fallDetectionService = FallDetectionService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupSubscribers()
    }
    
    private func setupSubscribers() {
        // Mirror geofence monitoring states
        geofenceService.$isMonitoring
            .receive(on: DispatchQueue.main)
            .assign(to: \.isGeofenceMonitoring, on: self)
            .store(in: &cancellables)
        
        geofenceService.$isInsideSafeZone
            .receive(on: DispatchQueue.main)
            .assign(to: \.isInsideSafeZone, on: self)
            .store(in: &cancellables)
        
        geofenceService.$currentMode
            .receive(on: DispatchQueue.main)
            .assign(to: \.monitoringMode, on: self)
            .store(in: &cancellables)
        
        geofenceService.$lastKnownLocation
            .receive(on: DispatchQueue.main)
            .assign(to: \.lastKnownLocation, on: self)
            .store(in: &cancellables)
        
        // Mirror fall detection monitoring state
        fallDetectionService.$isMonitoring
            .receive(on: DispatchQueue.main)
            .assign(to: \.isFallMonitoring, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Fetch Patient (OPTION 2 - Simplest)
    
    func fetchCurrentPatient() {
        print("📱 [WatchViewModel] fetchCurrentPatient called")
        isLoading = true
        errorMessage = nil
        
        // Use fetchCurrentPatient() - queries for the most recent patient
        cloudKitManager.fetchCurrentPatient { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let patient):
                    print("✅ [WatchViewModel] Patient loaded: \(patient.name)")
                    print("   Patient ID: \(patient.id)")
                    print("   Has safe zone: \(patient.hasSafeZone)")
                    
                    if patient.hasSafeZone {
                        print("   Safe zone: \(patient.safeZoneDisplayName)")
                        print("   Radius: \(patient.safeZoneRadius ?? 0)m")
                    }
                    
                    self?.currentPatient = patient
                    self?.startMonitoring(for: patient)
                    
                case .failure(let error):
                    print("❌ [WatchViewModel] Failed to fetch patient: \(error.localizedDescription)")
                    self?.errorMessage = "Could not load patient data"
                    
                    // Fallback to mock patient for testing
                    self?.useMockPatient()
                }
            }
        }
    }
    
    // MARK: - Start Monitoring
    
    private func startMonitoring(for patient: Patient) {
        print("🚀 [WatchViewModel] Starting monitoring for: \(patient.name)")
        
        // Start geofence monitoring (service fetches safe zone itself)
        geofenceService.startMonitoring(for: patient.id)
        
        // Log safe zone details if available
        if patient.hasSafeZone,
           let lat = patient.safeZoneCenterLat,
           let lon = patient.safeZoneCenterLon,
           let radius = patient.safeZoneRadius {
            
            let name = patient.safeZoneDisplayName
            
            print("📍 Starting geofence monitoring:")
            print("   Zone: \(name)")
            print("   Center: \(lat), \(lon)")
            print("   Radius: \(radius)m")
        } else {
            print("⚠️ No safe zone configured for patient")
        }
        
        // Start fall detection monitoring
        print("🏃 Starting fall detection monitoring")
        fallDetectionService.startMonitoring(for: patient.id)
    }
    
    // MARK: - Stop Monitoring
    
    func stopMonitoring() {
        print("⏹️ [WatchViewModel] Stopping all monitoring")
        geofenceService.stopMonitoring()
        fallDetectionService.stopMonitoring()
    }
    
    // MARK: - Mock Patient (Fallback for Testing)
    
    private func useMockPatient() {
        print("🧪 [WatchViewModel] Using MOCK patient for testing")
        
        let mockPatient = Patient(
            id: "MOCK-PATIENT-ID",
            name: "Ahmed Ali",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -75, to: Date()),
            caregiverId: "MOCK-CAREGIVER-ID",
            safeZoneName: "Home",
            safeZoneCenterLat: 24.7136,  // Riyadh
            safeZoneCenterLon: 46.6753,
            safeZoneRadius: 250.0,
            safeZoneIsActive: true,
            safeZoneCreatedAt: Date(),
            safeZoneUpdatedAt: Date()
        )
        
        DispatchQueue.main.async {
            self.currentPatient = mockPatient
            self.startMonitoring(for: mockPatient)
            
            print("✅ Mock patient loaded: \(mockPatient.name)")
            print("   Mock safe zone: \(mockPatient.safeZoneDisplayName)")
        }
    }
    
    // MARK: - Refresh Data
    
    func refresh() {
        print("🔄 [WatchViewModel] Refreshing patient data...")
        fetchCurrentPatient()
    }
    
    // MARK: - Manual Alert Testing (for development)
    
    func testFallAlert() {
        guard let patient = currentPatient else {
            print("❌ No patient available for testing")
            return
        }
        
        print("🧪 Creating test fall alert...")
        
        let alert = AlertEvent(
            patientId: patient.id,
            alertType: .fallDetected,
            timestamp: Date(),
            latitude: nil,
            longitude: nil,
            isRead: false,
            requiresConfirmation: false,
            confirmationStatus: .notApplicable
        )
        
        cloudKitManager.saveAlertEvent(alert) { result in
            switch result {
            case .success(let savedAlert):
                print("✅ Test alert created: \(savedAlert.id)")
            case .failure(let error):
                print("❌ Failed to create test alert: \(error)")
            }
        }
    }
    
    func testGeofenceAlert() {
        guard let patient = currentPatient else {
            print("❌ No patient available for testing")
            return
        }
        
        print("🧪 Creating test geofence exit alert...")
        
        let alert = AlertEvent(
            patientId: patient.id, // Note: struct uses patientId; initializer label is patientId
            alertType: .geofenceExit,
            timestamp: Date(),
            latitude: 24.7136,
            longitude: 46.6753,
            isRead: false,
            requiresConfirmation: true,
            confirmationStatus: .pending
        )
        
        cloudKitManager.saveAlertEvent(alert) { result in
            switch result {
            case .success(let savedAlert):
                print("✅ Test alert created: \(savedAlert.id)")
            case .failure(let error):
                print("❌ Failed to create test alert: \(error)")
            }
        }
    }
}

