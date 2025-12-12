//
//  FallDetectionService.swift
//  awn app
//
//  Created by Joud Almashgari on 11/12/2025.
//
//  Fall detection service for watchOS
//  Monitors accelerometer data and creates alerts with GPS location
//
//
//  FallDetectionService.swift
//  Awn Watch App
//
//  Fall detection service for watchOS
//  Fixed: Removed problematic allowsBackgroundLocationUpdates
//

import Foundation
import CoreMotion
import CoreLocation
import CloudKit
import Combine
import WatchKit

class FallDetectionService: NSObject, ObservableObject {
    
    static let shared = FallDetectionService()
    
    // MARK: - Published Properties
    @Published var isMonitoring: Bool = false
    @Published var lastFallDetectedAt: Date?
    
    // MARK: - Private Properties
    private let motionManager = CMMotionManager()
    private let locationManager = CLLocationManager()
    private let cloudKitManager = WatchCloudKitManager.shared
    
    private var patientID: String?
    private var fallDetectionTimer: Timer?
    
    // Fall detection thresholds
    private let fallAccelerationThreshold: Double = 2.5 // G-force
    private let fallDurationThreshold: TimeInterval = 0.5 // seconds
    
    // Debounce to prevent duplicate alerts
    private let alertCooldownPeriod: TimeInterval = 60.0 // 1 minute
    private var lastAlertTime: Date?
    
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
        // This line causes crashes on watchOS - not needed for basic location
    }
    
    // MARK: - Public Methods
    
    func startMonitoring(for patientID: String) {
        self.patientID = patientID
        
        // Check if device supports motion detection
        guard motionManager.isDeviceMotionAvailable else {
            print("❌ Device motion not available")
            return
        }
        
        // Request location permissions
        requestLocationPermissions()
        
        // Start motion updates
        startMotionUpdates()
        
        isMonitoring = true
        print("✅ Fall detection monitoring started")
    }
    
    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
        fallDetectionTimer?.invalidate()
        fallDetectionTimer = nil
        isMonitoring = false
        print("⏹️ Fall detection monitoring stopped")
    }
    
    // MARK: - Private Methods
    
    private func requestLocationPermissions() {
        let status = locationManager.authorizationStatus
        
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    private func startMotionUpdates() {
        // Configure motion manager
        motionManager.deviceMotionUpdateInterval = 0.1 // 10 Hz
        
        // Start updates
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self,
                  let motion = motion else { return }
            
            self.processMotionData(motion)
        }
    }
    
    private func processMotionData(_ motion: CMDeviceMotion) {
        // Get acceleration (gravity + user acceleration)
        let acceleration = motion.userAcceleration
        
        // Calculate total acceleration magnitude
        let magnitude = sqrt(
            pow(acceleration.x, 2) +
            pow(acceleration.y, 2) +
            pow(acceleration.z, 2)
        )
        
        // Check if acceleration exceeds threshold (potential fall)
        if magnitude > fallAccelerationThreshold {
            detectPotentialFall()
        }
    }
    
    private func detectPotentialFall() {
        // Check cooldown period to prevent duplicate alerts
        if let lastAlert = lastAlertTime,
           Date().timeIntervalSince(lastAlert) < alertCooldownPeriod {
            print("⏸️ Fall alert in cooldown period")
            return
        }
        
        print("⚠️ Potential fall detected!")
        
        // Get current GPS location
        getCurrentLocation { [weak self] location in
            self?.createFallAlert(at: location)
        }
    }
    
    private func getCurrentLocation(completion: @escaping (CLLocation?) -> Void) {
        // Request single location update
        locationManager.requestLocation()
        
        // Store completion handler with timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            completion(self?.locationManager.location)
        }
    }
    
    private func createFallAlert(at location: CLLocation?) {
        guard let patientID = patientID else { return }
        
        let alert = AlertEvent(
            patientId: patientID,
            alertType: .fallDetected,
            timestamp: Date(),
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude,
            isRead: false,
            requiresConfirmation: false,
            confirmationStatus: .notApplicable
        )
        
        // Save to CloudKit
        cloudKitManager.saveAlertEvent(alert) { [weak self] result in
            switch result {
            case .success(let savedAlert):
                print("🚨 Fall alert created: \(savedAlert.id)")
                
                if let lat = savedAlert.latitude, let lon = savedAlert.longitude {
                    print("📍 Location: \(lat), \(lon)")
                } else {
                    print("⚠️ No GPS location available")
                }
                
                // Update last alert time
                self?.lastAlertTime = Date()
                
                DispatchQueue.main.async {
                    self?.lastFallDetectedAt = Date()
                }
                
                // Post notification
                NotificationCenter.default.post(
                    name: Constants.Notifications.fallDetected,
                    object: savedAlert
                )
                
                // Trigger haptic feedback
                self?.triggerHapticFeedback()
                
            case .failure(let error):
                print("❌ Failed to save fall alert: \(error)")
            }
        }
    }
    
    private func triggerHapticFeedback() {
        WKInterfaceDevice.current().play(.notification)
    }
}

// MARK: - CLLocationManagerDelegate

extension FallDetectionService: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Location updates received
        if let location = locations.last {
            print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location manager error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("📍 Location authorization changed: \(status.rawValue)")
    }
}
