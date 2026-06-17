//
//  Constants.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  CloudKit and App Configuration
//
//
//
//  Constants.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  CloudKit and App Configuration
//
//
//  Constants.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//  Updated: Added isGuestUser key + LocationSharingRequest record type
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
            static let locationSharingRequest = "LocationSharingRequest" // ← NEW
        }

        // Field Names
        struct Field {
            static let appleUserID = "appleUserID"
            static let email = "email"
            static let fullName = "fullName"
            static let createdAt = "createdAt"
            static let updatedAt = "updatedAt"

            static let userReference = "userReference"
            static let relationship = "relationship"
            static let phoneNumber = "phoneNumber"
            static let linkedPatientId = "linkedPatientId"

            static let name = "name"
            static let dateOfBirth = "dateOfBirth"
            static let caregiverId = "caregiverId"

            static let watchDeviceID = "watchDeviceID"
            static let watchSerialNumber = "watchSerialNumber"
            static let watchPairedDate = "watchPairedDate"

            static let safeZoneName = "safeZoneName"
            static let safeZoneCenterLat = "safeZoneCenterLat"
            static let safeZoneCenterLon = "safeZoneCenterLon"
            static let safeZoneRadius = "safeZoneRadius"
            static let safeZoneIsActive = "safeZoneIsActive"
            static let safeZoneCreatedAt = "safeZoneCreatedAt"
            static let safeZoneUpdatedAt = "safeZoneUpdatedAt"

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

            static let medicationReference = "medicationReference"
            static let scheduledDateTime = "scheduledDateTime"
            static let status = "status"
            static let takenDateTime = "takenDateTime"
            static let confirmedBy = "confirmedBy"

            // LocationSharingRequest fields ← NEW
            static let locationRequestCaregiverId = "caregiverId"
            static let locationRequestPatientId = "patientId"
            static let caregiverName = "caregiverName"
            static let patientId = "patientId"
            static let requestedAt = "requestedAt"
            static let respondedAt = "respondedAt"
        }
    }

    // MARK: - Safe Zone Configuration
    struct SafeZone {
        static let minimumRadius: Double = 50.0
        static let maximumRadius: Double = 2000.0
        static let defaultRadius: Double = 500.0
    }

    // MARK: - Alert Configuration
    struct Alerts {
        static let autoConfirmationDelay: TimeInterval = 300
    }

    // MARK: - User Defaults Keys
    struct UserDefaultsKeys {
        static let isAuthenticated = "isAuthenticated"
        static let currentUserID = "currentUserID"
        static let userRole = "userRole"
        static let appleUserID = "appleUserID"
        static let currentPatientID = "currentPatientID"
        static let currentCaregiverID = "currentCaregiverID"
        static let isGuestUser = "isGuestUser"
        static let selectedRole = "selectedRole"          // caregiver | patient
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let locationPermissionHandled = "locationPermissionHandled" // ← NEW
    }

    // MARK: - Notification Names
    struct Notifications {
        static let userDidAuthenticate = Notification.Name("userDidAuthenticate")
        static let userDidLogout = Notification.Name("userDidLogout")

        static let safeZoneUpdated = Notification.Name("safeZoneUpdated")
        static let geofenceExitDetected = Notification.Name("geofenceExitDetected")
        static let geofenceEntryDetected = Notification.Name("geofenceEntryDetected")

        static let alertReceived = Notification.Name("alertReceived")
        static let fallDetected = Notification.Name("fallDetected")

        static let medicationAdded = Notification.Name("medicationAdded")
        static let medicationUpdated = Notification.Name("medicationUpdated")
        static let doseLogUpdated = Notification.Name("doseLogUpdated")

        // Location sharing ← NEW
        static let locationRequestReceived = Notification.Name("locationRequestReceived")
        static let locationRequestResponded = Notification.Name("locationRequestResponded")
    }

    // MARK: - Medication Configuration
    struct Medication {
        static let maxIntervalDays = 10
        static let minIntervalDays = 1
    }
}
