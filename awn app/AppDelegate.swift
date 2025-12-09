//
//  AppDelegate.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  App delegate for CloudKit
//

import UIKit
import CloudKit

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configure CloudKit
        setupCloudKit()
        
        // Request notification permissions
        registerForNotifications()
        
        return true
    }
    
    // MARK: - CloudKit Setup
    
    private func setupCloudKit() {
        // Check CloudKit account status
        CKContainer.default().accountStatus { status, error in
            if let error = error {
                print("❌ CloudKit account error: \(error.localizedDescription)")
                return
            }
            
            switch status {
            case .available:
                print("✅ CloudKit is available")
                self.setupCloudKitSubscriptions()
            case .noAccount:
                print("⚠️ No iCloud account")
            case .restricted:
                print("⚠️ iCloud is restricted")
            case .couldNotDetermine:
                print("⚠️ Could not determine iCloud status")
            case .temporarilyUnavailable:
                print("⚠️ iCloud temporarily unavailable")
            @unknown default:
                print("⚠️ Unknown iCloud status")
            }
        }
    }
    
    private func setupCloudKitSubscriptions() {
        // Subscribe to changes in relevant record types
        // This will be used for real-time updates in Phase 2 & 3
        
        let database = Constants.CloudKit.privateDatabase
        
        // Location updates subscription
        let locationPredicate = NSPredicate(value: true)
        let locationSubscription = CKQuerySubscription(
            recordType: Constants.CloudKit.RecordType.patient,
            predicate: locationPredicate,
            options: [.firesOnRecordUpdate]  // Changed from .firesOnRecordCreation
        )
        
        let locationNotification = CKSubscription.NotificationInfo()
        locationNotification.shouldSendContentAvailable = true
        locationSubscription.notificationInfo = locationNotification
        
        database.save(locationSubscription) { subscription, error in
            if let error = error {
                print("❌ Failed to save location subscription: \(error.localizedDescription)")
            } else {
                print("✅ Location subscription saved")
            }
        }
        
        // Alert subscription
        let alertPredicate = NSPredicate(value: true)
        let alertSubscription = CKQuerySubscription(
            recordType: Constants.CloudKit.RecordType.alertEvent,
            predicate: alertPredicate,
            options: [.firesOnRecordCreation]
        )
        
        let alertNotification = CKSubscription.NotificationInfo()
        alertNotification.shouldSendContentAvailable = true
        alertNotification.alertBody = "New alert from patient"
        alertSubscription.notificationInfo = alertNotification
        
        database.save(alertSubscription) { subscription, error in
            if let error = error {
                print("❌ Failed to save alert subscription: \(error.localizedDescription)")
            } else {
                print("✅ Alert subscription saved")
            }
        }
    }
    
    // MARK: - Notifications
    
    private func registerForNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ Registered for remote notifications")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
}

