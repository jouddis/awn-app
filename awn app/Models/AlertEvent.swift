//
//  AlertEvent.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  Alert events from Watch (geofence exits/entries, falls)

import Foundation
import CloudKit
import CoreLocation

enum AlertType: String, Codable {
    case geofenceExit = "GEOFENCE_EXIT"
    case geofenceEntry = "GEOFENCE_ENTRY"
    case fallDetected = "FALL_DETECTED"
    
    var displayName: String {
        switch self {
        case .geofenceExit: return "Left Safe Zone"
        case .geofenceEntry: return "Returned to Safe Zone"
        case .fallDetected: return "Fall Detected"
        }
    }
    
    var emoji: String {
        switch self {
        case .geofenceExit: return "🚶"
        case .geofenceEntry: return "✅"
        case .fallDetected: return "🚨"
        }
    }
}

enum ConfirmationStatus: String, Codable {
    case pending = "PENDING"
    case accompanied = "ACCOMPANIED"
    case wandering = "WANDERING"
    case notApplicable = "NOT_APPLICABLE"
    
    var displayName: String {
        switch self {
        case .pending: return "Awaiting Confirmation"
        case .accompanied: return "With Caregiver"
        case .wandering: return "Wandering Incident"
        case .notApplicable: return "—"
        }
    }
}

struct AlertEvent: Identifiable, Codable {
    let id: String
    let patientId: String
    let alertType: AlertType
    let timestamp: Date
    
    // Location data (optional for entries, required for exits/falls)
    var latitude: Double?
    var longitude: Double?
    
    // Alert status
    var isRead: Bool
    
    // Wandering confirmation (for geofence exits only)
    var requiresConfirmation: Bool
    var confirmationStatus: ConfirmationStatus
    var confirmedAt: Date?
    var autoConfirmedAt: Date?
    
    var createdAt: Date
    
    // MARK: - Initialization
    
    init(id: String = UUID().uuidString,
         patientId: String,
         alertType: AlertType,
         timestamp: Date = Date(),
         latitude: Double? = nil,
         longitude: Double? = nil,
         isRead: Bool = false,
         requiresConfirmation: Bool? = nil,
         confirmationStatus: ConfirmationStatus? = nil,
         confirmedAt: Date? = nil,
         autoConfirmedAt: Date? = nil,
         createdAt: Date = Date()) {
        self.id = id
        self.patientId = patientId
        self.alertType = alertType
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.isRead = isRead
        
        // Auto-determine if confirmation needed
        self.requiresConfirmation = requiresConfirmation ?? (alertType == .geofenceExit)
        
        // Auto-set confirmation status
        if alertType == .geofenceExit {
            self.confirmationStatus = confirmationStatus ?? .pending
        } else {
            self.confirmationStatus = .notApplicable
        }
        
        self.confirmedAt = confirmedAt
        self.autoConfirmedAt = autoConfirmedAt
        self.createdAt = createdAt
    }
    
    // MARK: - Computed Properties
    
    var hasLocation: Bool {
        return latitude != nil && longitude != nil
    }
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    var isPendingConfirmation: Bool {
        return requiresConfirmation && confirmationStatus == .pending
    }
    
    var isWanderingIncident: Bool {
        return confirmationStatus == .wandering
    }
    
    var displayTitle: String {
        return alertType.displayName
    }
    
    var displayMessage: String {
        switch alertType {
        case .geofenceExit:
            if confirmationStatus == .accompanied {
                return "Patient left safe zone with caregiver"
            } else if confirmationStatus == .wandering {
                return "Patient wandered outside safe zone"
            } else {
                return "Patient left safe zone - confirmation needed"
            }
        case .geofenceEntry:
            return "Patient returned to safe zone"
        case .fallDetected:
            return "Fall detected - immediate attention needed"
        }
    }
    
    // MARK: - CloudKit Conversion
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Constants.CloudKit.RecordType.alertEvent)
        record["id"] = id as CKRecordValue
        
        // Patient reference
        let patientReference = CKRecord.Reference(
            recordID: CKRecord.ID(recordName: patientId),
            action: .none  // ← Change from .deleteSelf
        )
        record["patientReference"] = patientReference
        
        record["alertType"] = alertType.rawValue as CKRecordValue
        record["timestamp"] = timestamp as CKRecordValue
        
        if let latitude = latitude {
            record["latitude"] = latitude as CKRecordValue
        }
        
        if let longitude = longitude {
            record["longitude"] = longitude as CKRecordValue
        }
        
        record["isRead"] = (isRead ? 1 : 0) as CKRecordValue
        record["requiresConfirmation"] = (requiresConfirmation ? 1 : 0) as CKRecordValue
        record["confirmationStatus"] = confirmationStatus.rawValue as CKRecordValue
        
        if let confirmedAt = confirmedAt {
            record["confirmedAt"] = confirmedAt as CKRecordValue
        }
        
        if let autoConfirmedAt = autoConfirmedAt {
            record["autoConfirmedAt"] = autoConfirmedAt as CKRecordValue
        }
        
        record["createdAt"] = createdAt as CKRecordValue
        
        return record
    }
    
    init?(from record: CKRecord) {
        guard let id = record["id"] as? String,
              let patientRef = record["patientReference"] as? CKRecord.Reference,
              let alertTypeRaw = record["alertType"] as? String,
              let alertType = AlertType(rawValue: alertTypeRaw),
              let timestamp = record["timestamp"] as? Date,
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }
        
        self.id = id
        self.patientId = patientRef.recordID.recordName
        self.alertType = alertType
        self.timestamp = timestamp
        
        self.latitude = record["latitude"] as? Double
        self.longitude = record["longitude"] as? Double
        
        let isReadInt = record["isRead"] as? Int ?? 0
        self.isRead = isReadInt == 1
        
        let requiresConfirmationInt = record["requiresConfirmation"] as? Int ?? 0
        self.requiresConfirmation = requiresConfirmationInt == 1
        
        let statusRaw = record["confirmationStatus"] as? String ?? "NOT_APPLICABLE"
        self.confirmationStatus = ConfirmationStatus(rawValue: statusRaw) ?? .notApplicable
        
        self.confirmedAt = record["confirmedAt"] as? Date
        self.autoConfirmedAt = record["autoConfirmedAt"] as? Date
        
        self.createdAt = createdAt
    }
    
    // MARK: - Helper Methods
    
    mutating func markAsRead() {
        self.isRead = true
    }
    
    mutating func confirmAccompanied() {
        guard requiresConfirmation else { return }
        self.confirmationStatus = .accompanied
        self.confirmedAt = Date()
    }
    
    mutating func confirmWandering() {
        guard requiresConfirmation else { return }
        self.confirmationStatus = .wandering
        self.confirmedAt = Date()
    }
    
    mutating func autoConfirmAsWandering() {
        guard requiresConfirmation && confirmationStatus == .pending else { return }
        self.confirmationStatus = .wandering
        self.autoConfirmedAt = Date()
    }
}

