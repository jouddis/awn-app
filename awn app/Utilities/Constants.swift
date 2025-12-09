//
//  Constants.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  CloudKit and App Configuration
//

import Foundation
import CloudKit

struct Constants {
    
    // MARK: - CloudKit Configuration
    struct CloudKit {
        static let containerIdentifier = "iCloud.com.Awn.Awn"
        static let container = CKContainer(identifier: containerIdentifier)
        static let publicDatabase = container.publicCloudDatabase
        static let privateDatabase = container.privateCloudDatabase
        
        // Record Types
        struct RecordType {
            static let appUser = "AppUser"
            static let caregiver = "Caregiver"
            static let patient = "Patient"
            static let alertEvent = "AlertEvent"
            static let medication = "Medication"
            static let medicationDoseLog = "MedicationDoseLog"
            static let wanderingStats = "WanderingStats"
//            static let location = "Location"
            static let safeZone = "SafeZone"

        }
        
        // Field Names
        struct Field {
            // AppUser
            static let appleUserID = "appleUserID"
            static let email = "email"
            static let fullName = "fullName"
            static let role = "role"
            static let createdAt = "createdAt"
            static let updatedAt = "updatedAt"
            
            // Caregiver
            static let userReference = "userReference"
            static let relationship = "relationship"
            static let phoneNumber = "phoneNumber"
            static let linkedPatientId = "linkedPatientId"
            
            // Patient
            static let userId = "userId"
            static let name = "name"
            static let dateOfBirth = "dateOfBirth"
            static let caregiverId = "caregiverId"
            
            // Patient - Safe Zone
            static let safeZoneName = "safeZoneName"
            static let safeZoneCenterLat = "safeZoneCenterLat"
            static let safeZoneCenterLon = "safeZoneCenterLon"
            static let safeZoneRadius = "safeZoneRadius"
            static let safeZoneIsActive = "safeZoneIsActive"
            static let safeZoneCreatedAt = "safeZoneCreatedAt"
            static let safeZoneUpdatedAt = "safeZoneUpdatedAt"
            
            // AlertEvent
            static let patientReference = "patientReference"
            static let alertType = "alertType"
            static let timestamp = "timestamp"
            static let latitude = "latitude"
            static let longitude = "longitude"
            static let isRead = "isRead"
            static let requiresConfirmation = "requiresConfirmation"
            static let confirmationStatus = "confirmationStatus"
            static let confirmedAt = "confirmedAt"
            static let autoConfirmedAt = "autoConfirmedAt"
            
            // Medication
            static let medicationName = "medicationName"
            static let medicationType = "medicationType"
            static let dosage = "dosage"
            static let shape = "shape"
            static let notes = "notes"
            static let frequencyType = "frequencyType"
            static let intervalDays = "intervalDays"
            static let startDate = "startDate"
            static let weekDays = "weekDays"
            static let maxDosesPerDay = "maxDosesPerDay"
            static let scheduledTimes = "scheduledTimes"
            static let isActive = "isActive"
            
            // MedicationDoseLog
            static let medicationReference = "medicationReference"
            static let scheduledDateTime = "scheduledDateTime"
            static let status = "status"
            static let takenDateTime = "takenDateTime"
            static let confirmedBy = "confirmedBy"
            
            // WanderingStats
            static let date = "date"
            static let wanderingCount = "wanderingCount"
            static let accompaniedCount = "accompaniedCount"
            static let totalExits = "totalExits"
            static let averageDuration = "averageDuration"
            static let longestDuration = "longestDuration"
        }
    }
    
    // MARK: - Safe Zone Configuration
    struct SafeZone {
        static let minimumRadius: Double = 50.0      // 50 meters
        static let maximumRadius: Double = 2000.0    // 2 kilometers
        static let defaultRadius: Double = 500.0     // 500 meters
    }
    
    // MARK: - Alert Configuration
    struct Alerts {
        static let autoConfirmationDelay: TimeInterval = 300  // 5 minutes
    }
    
    // MARK: - Invite Links (URL Scheme - No domain needed!)
    struct InviteLinks {
        static let scheme = "awn"
        static let invitePath = "join"
        
        static func inviteURL(token: String) -> URL? {
            return URL(string: "\(scheme)://\(invitePath)/\(token)")
        }
    }
    
    // MARK: - User Defaults Keys
    struct UserDefaultsKeys {
        static let isAuthenticated = "isAuthenticated"
        static let currentUserID = "currentUserID"
        static let userRole = "userRole"
        static let appleUserID = "appleUserID"
        static let currentPatientID = "currentPatientID"
        static let currentCaregiverID = "currentCaregiverID"
    }
    
    // MARK: - Notification Names
    struct Notifications {
        static let userDidAuthenticate = Notification.Name("userDidAuthenticate")
        static let userDidLogout = Notification.Name("userDidLogout")
        static let inviteLinkReceived = Notification.Name("inviteLinkReceived")
        
        // Location
        static let safeZoneUpdated = Notification.Name("safeZoneUpdated")
        static let geofenceExitDetected = Notification.Name("geofenceExitDetected")
        static let geofenceEntryDetected = Notification.Name("geofenceEntryDetected")
        
        // Alerts
        static let alertReceived = Notification.Name("alertReceived")
        static let fallDetected = Notification.Name("fallDetected")
        
        // Medications
        static let medicationAdded = Notification.Name("medicationAdded")
        static let medicationUpdated = Notification.Name("medicationUpdated")
        static let doseLogUpdated = Notification.Name("doseLogUpdated")
    }
    
    // MARK: - Medication Configuration
    struct Medication {
        static let maxIntervalDays = 10
        static let minIntervalDays = 1
    }
}


