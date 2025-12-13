//
//  GeofenceService.swift
//  awn app
//
//  Created by Joud Almashgari on 11/12/2025.
//  watchOS-compatible geofence monitoring
//  Uses: Timer-based checks + Extended runtime (no region monitoring)
//
//  GeofenceService.swift
//  Awn Watch App
//
//  watchOS-compatible geofence monitoring
//  Uses: Timer-based checks + Extended runtime (no region monitoring)
//

import Foundation
import CoreLocation
import CloudKit
import Combine
import WatchKit

class GeofenceService: NSObject, ObservableObject {
    
    static let shared = GeofenceService()
    
    // MARK: - Published Properties
    @Published var isMonitoring: Bool = false
    @Published var currentSafeZone: Patient?
    @Published var isInsideSafeZone: Bool = false  // Start as false to detect first entry
    
    // Track if we've done initial check
    private var hasPerformedInitialCheck: Bool = false
    @Published var lastKnownLocation: CLLocation?
    @Published var currentMode: MonitoringMode = .highPower // Always high power on watch
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private let cloudKitManager = WatchCloudKitManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private var patientID: String?
    private var monitoringTimer: Timer?
    
    // Safe zone properties
    private var safeZoneCenter: CLLocationCoordinate2D?
    private var safeZoneRadius: Double?
    
    // Extended runtime
    private var extendedSession: WKExtendedRuntimeSession?
    
    // Check interval (30 seconds)
    private let checkInterval: TimeInterval = 30.0
    
    // MARK: - Monitoring Mode Enum
    enum MonitoringMode: String {
        case lowPower = "Low Power" // Not used on watch
        case highPower = "Active Tracking"
    }
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // Removed: locationManager.allowsBackgroundLocationUpdates = true
        // This causes crashes on watchOS - not needed for location monitoring
    }
    
    // MARK: - Public Methods
    
    func startMonitoring(for patientID: String) {
        self.patientID = patientID
        
        // Request location permissions
        requestLocationPermissions()
        
        // Fetch patient's safe zone from CloudKit
        fetchSafeZone()
    }
    
    func stopMonitoring() {
        locationManager.stopUpdatingLocation()
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        stopExtendedRuntime()
        
        isMonitoring = false
        print("⏹️ Geofence monitoring stopped")
    }
    
    func refreshSafeZone() {
        fetchSafeZone()
    }
    
    // MARK: - Private Methods
    
    private func requestLocationPermissions() {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            break
        case .denied, .restricted:
            print("⚠️ Location permission denied")
        @unknown default:
            break
        }
    }
    
    private func fetchSafeZone() {
        guard let patientID = patientID else { return }
        
        cloudKitManager.fetchPatient(byID: patientID) { [weak self] result in
            switch result {
            case .success(let patient):
                DispatchQueue.main.async {
                    self?.currentSafeZone = patient
                    self?.setupMonitoring(for: patient)
                }
            case .failure(let error):
                print("❌ Failed to fetch patient safe zone: \(error)")
            }
        }
    }
    
    private func setupMonitoring(for patient: Patient) {
        // Validate safe zone
        guard patient.hasSafeZone,
              let lat = patient.safeZoneCenterLat,
              let lon = patient.safeZoneCenterLon,
              let radius = patient.safeZoneRadius,
              patient.safeZoneIsActive else {
            print("⚠️ Patient has no active safe zone")
            return
        }
        
        // Store safe zone info
        safeZoneCenter = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        safeZoneRadius = radius
        
        // Start extended runtime
        startExtendedRuntime()
        
        // Start location updates
        locationManager.startUpdatingLocation()
        
        // Start periodic checking
        startPeriodicChecking()
        
        isMonitoring = true
        currentMode = .highPower
        
        print("✅ Started geofence monitoring: \(patient.safeZoneDisplayName)")
        print("📍 Center: \(lat), \(lon)")
        print("⭕ Radius: \(radius)m")
        print("⚡ Mode: Active tracking (30s checks)")
        print("🔋 Battery: High drain (necessary for continuous monitoring)")
    }
    
    // MARK: - Extended Runtime
    
    private func startExtendedRuntime() {
        guard extendedSession == nil else {
            print("⚡ Extended runtime already active")
            return
        }
        
        let session = WKExtendedRuntimeSession()
        session.delegate = self
        
        extendedSession = session
        session.start()
        
        print("⚡ Extended runtime session started")
    }
    
    private func stopExtendedRuntime() {
        extendedSession?.invalidate()
        extendedSession = nil
        print("⚡ Extended runtime session stopped")
    }
    
    // MARK: - Periodic Checking
    
    private func startPeriodicChecking() {
        monitoringTimer?.invalidate()
        
        monitoringTimer = Timer.scheduledTimer(
            withTimeInterval: checkInterval,
            repeats: true
        ) { [weak self] _ in
            self?.checkGeofenceStatus()
        }
        
        // Run first check immediately
        checkGeofenceStatus()
        
        print("⏱️ Periodic checking started (every \(checkInterval)s)")
    }
    
    private func checkGeofenceStatus() {
        guard let currentLocation = locationManager.location,
              let center = safeZoneCenter,
              let radius = safeZoneRadius else {
            return
        }
        
        // Calculate distance
        let safeZoneLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let distance = currentLocation.distance(from: safeZoneLocation)
        
        let wasInside = isInsideSafeZone
        let isNowInside = distance <= radius
        
        print("📍 Location check: \(distance.rounded())m from center (radius: \(radius)m)")
        
        // On first check, just set state without creating alert
        if !hasPerformedInitialCheck {
            hasPerformedInitialCheck = true
            print("🔍 Initial state: \(isNowInside ? "Inside" : "Outside") safe zone")
            DispatchQueue.main.async {
                self.isInsideSafeZone = isNowInside
                self.lastKnownLocation = currentLocation
            }
            return
        }
        
        // Detect transitions (after initial check)
        if wasInside && !isNowInside {
            handleGeofenceExit(at: currentLocation)
        } else if !wasInside && isNowInside {
            handleGeofenceEntry(at: currentLocation)
        }
        
        // Update status
        DispatchQueue.main.async {
            self.isInsideSafeZone = isNowInside
            self.lastKnownLocation = currentLocation
        }
    }
    
    // MARK: - Alert Creation
    
    private func handleGeofenceExit(at location: CLLocation) {
        print("⚠️ GEOFENCE EXIT DETECTED")
        print("   Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        createGeofenceExitAlert(at: location)
    }
    
    private func handleGeofenceEntry(at location: CLLocation) {
        print("✅ GEOFENCE ENTRY DETECTED")
        print("   Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        createGeofenceEntryAlert(at: location)
    }
    
    private func createGeofenceExitAlert(at location: CLLocation?) {
        guard let patientID = patientID else { return }
        
        let alert = AlertEvent(
            patientId: patientID,
            alertType: .geofenceExit,
            timestamp: Date(),
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude,
            isRead: false,
            requiresConfirmation: true,
            confirmationStatus: .pending
        )
        
        cloudKitManager.saveAlertEvent(alert) { result in
            switch result {
            case .success(let savedAlert):
                print("✅ Geofence exit alert created: \(savedAlert.id)")
                
                NotificationCenter.default.post(
                    name: Constants.Notifications.geofenceExitDetected,
                    object: savedAlert
                )
                
                self.scheduleAutoConfirmation(for: savedAlert.id)
                
            case .failure(let error):
                print("❌ Failed to save geofence exit alert: \(error)")
            }
        }
    }
    
    private func createGeofenceEntryAlert(at location: CLLocation?) {
        guard let patientID = patientID else { return }
        
        let alert = AlertEvent(
            patientId: patientID,
            alertType: .geofenceEntry,
            timestamp: Date(),
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude,
            isRead: false,
            requiresConfirmation: false,
            confirmationStatus: .notApplicable
        )
        
        cloudKitManager.saveAlertEvent(alert) { result in
            switch result {
            case .success(let savedAlert):
                print("✅ Geofence entry alert created: \(savedAlert.id)")
                
                NotificationCenter.default.post(
                    name: Constants.Notifications.geofenceEntryDetected,
                    object: savedAlert
                )
                
            case .failure(let error):
                print("❌ Failed to save geofence entry alert: \(error)")
            }
        }
    }
    
    private func scheduleAutoConfirmation(for alertID: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.Alerts.autoConfirmationDelay) { [weak self] in
            self?.autoConfirmWandering(alertID: alertID)
        }
    }
    
    private func autoConfirmWandering(alertID: String) {
        let recordID = CKRecord.ID(recordName: alertID)
        
        cloudKitManager.privateDatabase.fetch(withRecordID: recordID) { record, error in
            guard let record = record,
                  let statusRaw = record["confirmationStatus"] as? String,
                  statusRaw == ConfirmationStatus.pending.rawValue else {
                return
            }
            
            record["confirmationStatus"] = ConfirmationStatus.wandering.rawValue as CKRecordValue
            record["autoConfirmedAt"] = Date() as CKRecordValue
            
            self.cloudKitManager.privateDatabase.save(record) { _, saveError in
                if let saveError = saveError {
                    print("❌ Failed to auto-confirm: \(saveError)")
                } else {
                    print("⏰ Auto-confirmed alert as wandering: \(alertID)")
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension GeofenceService: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.lastKnownLocation = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location manager error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("📍 Location authorization changed: \(status.rawValue)")
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            if !isMonitoring, patientID != nil {
                fetchSafeZone()
            }
        }
    }
}

// MARK: - WKExtendedRuntimeSessionDelegate

extension GeofenceService: WKExtendedRuntimeSessionDelegate {
    
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("✅ Extended runtime session active")
    }
    
    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("⚠️ Extended runtime session expiring - attempting restart")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            if self?.isMonitoring == true {
                self?.startExtendedRuntime()
            }
        }
    }
    
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession,
                                didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
                                error: Error?) {
        
        // Simple approach: Just log that it invalidated
        print("⚠️ Extended runtime invalidated")
        if let error = error {
            print("   Error: \(error.localizedDescription)")
        }
        
        extendedSession = nil
        
        // Attempt restart if still monitoring
        if isMonitoring {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.startExtendedRuntime()
            }
        }
    }
}
