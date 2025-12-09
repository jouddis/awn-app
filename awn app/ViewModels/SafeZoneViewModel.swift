//
//  SafeZoneViewModel.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  Complete view model for safe zone management
//

import Foundation
import MapKit
import CoreLocation
import Combine

enum SafeZoneState {
    case noZone
    case pickingLocation
    case namingZone
    case viewing
}

class SafeZoneViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentState: SafeZoneState = .noZone
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753), // Riyadh
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    @Published var radius: Double = 305.0
    @Published var zoneName: String = ""
    @Published var notificationsEnabled: Bool = true
    @Published var selectedAddress: String = "3501-13216, Alhamera -6900"
    
    @Published var hasPatient: Bool = false
    @Published var isLoading: Bool = false
    @Published var showSuccessAlert: Bool = false
    @Published var showDeleteAlert: Bool = false // ✨ NEW: For delete confirmation
    
    @Published var patientName: String = "Norah"
    
    // MARK: - Private Properties
    
    private let cloudKitManager = CloudKitManager.shared
    private let authService = AuthenticationService.shared
    private let locationManager = CLLocationManager()
    
    private var currentPatient: Patient?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var circleSize: CGFloat {
        // Calculate visual circle size based on map zoom and radius
        let metersPerPoint = region.span.latitudeDelta * 111000 / 300
        return CGFloat(radius * 2 / metersPerPoint)
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Load Data
    
    func loadPatientData() {
        guard let currentUser = authService.currentUser else {
            hasPatient = false
            return
        }
        
        isLoading = true
        
        // Fetch caregiver to get linked patient
        cloudKitManager.fetchCaregiver(byUserID: currentUser.id) { [weak self] result in
            switch result {
            case .success(let caregiver):
                if let patientID = caregiver.linkedPatientId {
                    self?.loadPatient(patientID: patientID)
                } else {
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        self?.hasPatient = false
                    }
                }
            case .failure(let error):
                print("❌ Failed to load caregiver: \(error)")
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.hasPatient = false
                }
            }
        }
    }
    
    private func loadPatient(patientID: String) {
        cloudKitManager.fetchPatient(byID: patientID) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let patient):
                    self?.currentPatient = patient
                    self?.hasPatient = true
                    self?.patientName = patient.name
                    self?.loadExistingZone(from: patient)
                    
                case .failure(let error):
                    print("❌ Failed to load patient: \(error)")
                    self?.hasPatient = false
                }
            }
        }
    }
    
    private func loadExistingZone(from patient: Patient) {
        if let lat = patient.safeZoneCenterLat,
           let lon = patient.safeZoneCenterLon,
           let radius = patient.safeZoneRadius,
           let name = patient.safeZoneName {
            
            // Has existing safe zone
            self.zoneName = name
            self.radius = radius
            self.notificationsEnabled = patient.safeZoneIsActive
            
            // Center map on safe zone
            self.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            
            self.currentState = .viewing
        } else {
            // No safe zone - show empty state
            self.currentState = .noZone
            locationManager.requestLocation()
        }
    }
    
    // MARK: - Actions
    
    func startCreatingZone() {
        // Request location permission if needed
        let status = locationManager.authorizationStatus
        
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        // Move to picking location state
        currentState = .pickingLocation
        
        // Center on current location if available
        if let location = locationManager.location {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    func confirmLocation() {
        // Move to naming screen
        currentState = .namingZone
        
        // Reverse geocode to get address
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let placemark = placemarks?.first {
                let address = [
                    placemark.subThoroughfare,
                    placemark.thoroughfare,
                    placemark.locality
                ].compactMap { $0 }.joined(separator: ", ")
                
                DispatchQueue.main.async {
                    self?.selectedAddress = address
                }
            }
        }
    }
    
    func saveZone() {
        guard var patient = currentPatient else { return }
        guard !zoneName.isEmpty else { return }
        
        // Update patient with safe zone data
        patient.safeZoneName = zoneName
        patient.safeZoneCenterLat = region.center.latitude
        patient.safeZoneCenterLon = region.center.longitude
        patient.safeZoneRadius = radius
        patient.safeZoneIsActive = notificationsEnabled
        patient.safeZoneCreatedAt = patient.safeZoneCreatedAt ?? Date()
        patient.safeZoneUpdatedAt = Date()
        
        isLoading = true
        
        cloudKitManager.savePatient(patient) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let savedPatient):
                    print("✅ Safe zone saved: \(self?.zoneName ?? "")")
                    self?.currentPatient = savedPatient
                    self?.showSuccessAlert = true
                    self?.currentState = .viewing // Revert to viewing state after successful save
                    
                case .failure(let error):
                    print("❌ Failed to save safe zone: \(error)")
                }
            }
        }
    }
    
    func updateNotificationSettings() {
        guard var patient = currentPatient else { return }
        
        patient.safeZoneIsActive = notificationsEnabled
        patient.safeZoneUpdatedAt = Date()
        
        cloudKitManager.savePatient(patient) { [weak self] result in
            switch result {
            case .success(let savedPatient):
                print("✅ Notification settings updated")
                self?.currentPatient = savedPatient
                
            case .failure(let error):
                print("❌ Failed to update notification settings: \(error)")
            }
        }
    }
    
    // ✨ NEW: Action to enter map editing mode
    func editZone() {
        currentState = .pickingLocation
    }
    
    // ✨ NEW: Action to delete the safe zone
    func deleteZone() {
        guard var patient = currentPatient else { return }
        
        // Clear all safe zone data on the patient record
        patient.safeZoneName = nil
        patient.safeZoneCenterLat = nil
        patient.safeZoneCenterLon = nil
        patient.safeZoneRadius = nil
        patient.safeZoneIsActive = false
        patient.safeZoneUpdatedAt = Date()
        
        isLoading = true
        showDeleteAlert = false // Dismiss alert
        
        cloudKitManager.savePatient(patient) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let updatedPatient):
                    print("✅ Safe zone deleted")
                    self?.currentPatient = updatedPatient
                    self?.currentState = .noZone // Go back to no zone state
                    // Reset transient properties
                    self?.zoneName = ""
                    self?.radius = 305.0
                    self?.notificationsEnabled = true
                    
                case .failure(let error):
                    print("❌ Failed to delete safe zone: \(error)")
                    // Optionally show an error alert here
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension SafeZoneViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            // Only update region if not already viewing a saved zone
            if self.currentState != .viewing {
                self.region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("📍 Location authorization: \(status.rawValue)")
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }
}

