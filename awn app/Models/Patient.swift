//
//  Patient.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  Patient model with single safe zone (geofence)
//

import Foundation
import CloudKit

struct Patient: Identifiable, Codable {
    let id: String
    var name: String
    var dateOfBirth: Date?
    var caregiverId: String // Reference to Caregiver (required)
    
    // Watch Pairing (Family Setup)
    var watchDeviceID: String? // Primary identifier for the paired watch
    var watchSerialNumber: String? // Backup identifier
    var watchPairedDate: Date? // When watch was paired via Family Setup
    
    // Single Safe Zone (Geofence)
    var safeZoneName: String?
    var safeZoneCenterLat: Double?
    var safeZoneCenterLon: Double?
    var safeZoneRadius: Double? // 50-2000 meters
    var safeZoneIsActive: Bool
    var safeZoneCreatedAt: Date?
    var safeZoneUpdatedAt: Date?
    
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initialization
    
    init(id: String = UUID().uuidString,
         name: String,
         dateOfBirth: Date? = nil,
         caregiverId: String,
         watchDeviceID: String? = nil,
         watchSerialNumber: String? = nil,
         watchPairedDate: Date? = nil,
         safeZoneName: String? = nil,
         safeZoneCenterLat: Double? = nil,
         safeZoneCenterLon: Double? = nil,
         safeZoneRadius: Double? = nil,
         safeZoneIsActive: Bool = false,
         safeZoneCreatedAt: Date? = nil,
         safeZoneUpdatedAt: Date? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.caregiverId = caregiverId
        self.watchDeviceID = watchDeviceID
        self.watchSerialNumber = watchSerialNumber
        self.watchPairedDate = watchPairedDate
        self.safeZoneName = safeZoneName
        self.safeZoneCenterLat = safeZoneCenterLat
        self.safeZoneCenterLon = safeZoneCenterLon
        self.safeZoneRadius = safeZoneRadius
        self.safeZoneIsActive = safeZoneIsActive
        self.safeZoneCreatedAt = safeZoneCreatedAt
        self.safeZoneUpdatedAt = safeZoneUpdatedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    var hasSafeZone: Bool {
        return safeZoneCenterLat != nil &&
               safeZoneCenterLon != nil &&
               safeZoneRadius != nil
    }
    
    var safeZoneDisplayName: String {
        return safeZoneName ?? "Safe Zone"
    }
    
    var safeZoneRadiusInKm: Double? {
        guard let radius = safeZoneRadius else { return nil }
        return radius / 1000.0
    }
    
    var isWatchPaired: Bool {
        return watchDeviceID != nil
    }
    
    // MARK: - CloudKit Conversion
    
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: Constants.CloudKit.RecordType.patient, recordID: recordID)
        
        record["id"] = id as CKRecordValue
        record["name"] = name as CKRecordValue
        
        if let dateOfBirth = dateOfBirth {
            record["dateOfBirth"] = dateOfBirth as CKRecordValue
        }
        
        // Store caregiverId as STRING (not reference to avoid cycles)
        record["caregiverId"] = caregiverId as CKRecordValue
        
        // Watch pairing fields
        if let watchDeviceID = watchDeviceID {
            record["watchDeviceID"] = watchDeviceID as CKRecordValue
        }
        
        if let watchSerialNumber = watchSerialNumber {
            record["watchSerialNumber"] = watchSerialNumber as CKRecordValue
        }
        
        if let watchPairedDate = watchPairedDate {
            record["watchPairedDate"] = watchPairedDate as CKRecordValue
        }
        
        // Safe zone fields
        if let safeZoneName = safeZoneName {
            record["safeZoneName"] = safeZoneName as CKRecordValue
        }
        
        if let lat = safeZoneCenterLat {
            record["safeZoneCenterLat"] = lat as CKRecordValue
        }
        
        if let lon = safeZoneCenterLon {
            record["safeZoneCenterLon"] = lon as CKRecordValue
        }
        
        if let radius = safeZoneRadius {
            record["safeZoneRadius"] = radius as CKRecordValue
        }
        
        record["safeZoneIsActive"] = (safeZoneIsActive ? 1 : 0) as CKRecordValue
        
        if let safeZoneCreatedAt = safeZoneCreatedAt {
            record["safeZoneCreatedAt"] = safeZoneCreatedAt as CKRecordValue
        }
        
        if let safeZoneUpdatedAt = safeZoneUpdatedAt {
            record["safeZoneUpdatedAt"] = safeZoneUpdatedAt as CKRecordValue
        }
        
        record["createdAt"] = createdAt as CKRecordValue
        record["updatedAt"] = updatedAt as CKRecordValue
        
        return record
    }
    
    init?(from record: CKRecord) {
        guard let id = record["id"] as? String,
              let name = record["name"] as? String,
              let caregiverId = record["caregiverId"] as? String,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.dateOfBirth = record["dateOfBirth"] as? Date
        self.caregiverId = caregiverId
        
        // Watch pairing fields
        self.watchDeviceID = record["watchDeviceID"] as? String
        self.watchSerialNumber = record["watchSerialNumber"] as? String
        self.watchPairedDate = record["watchPairedDate"] as? Date
        
        // Safe zone fields
        self.safeZoneName = record["safeZoneName"] as? String
        self.safeZoneCenterLat = record["safeZoneCenterLat"] as? Double
        self.safeZoneCenterLon = record["safeZoneCenterLon"] as? Double
        self.safeZoneRadius = record["safeZoneRadius"] as? Double
        
        let isActive = record["safeZoneIsActive"] as? Int ?? 0
        self.safeZoneIsActive = isActive == 1
        
        self.safeZoneCreatedAt = record["safeZoneCreatedAt"] as? Date
        self.safeZoneUpdatedAt = record["safeZoneUpdatedAt"] as? Date
        
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Helper Methods
    
    mutating func pairWatch(deviceID: String, serialNumber: String? = nil) {
        self.watchDeviceID = deviceID
        self.watchSerialNumber = serialNumber
        self.watchPairedDate = Date()
        self.updatedAt = Date()
    }
    
    mutating func unpairWatch() {
        self.watchDeviceID = nil
        self.watchSerialNumber = nil
        self.watchPairedDate = nil
        self.updatedAt = Date()
    }
    
    mutating func setSafeZone(name: String, centerLat: Double, centerLon: Double, radius: Double) {
        self.safeZoneName = name
        self.safeZoneCenterLat = centerLat
        self.safeZoneCenterLon = centerLon
        self.safeZoneRadius = radius
        self.safeZoneIsActive = true
        self.safeZoneCreatedAt = safeZoneCreatedAt ?? Date()
        self.safeZoneUpdatedAt = Date()
        self.updatedAt = Date()
    }
    
    mutating func updateSafeZone(name: String? = nil,
                                centerLat: Double? = nil,
                                centerLon: Double? = nil,
                                radius: Double? = nil) {
        if let name = name {
            self.safeZoneName = name
        }
        if let lat = centerLat {
            self.safeZoneCenterLat = lat
        }
        if let lon = centerLon {
            self.safeZoneCenterLon = lon
        }
        if let radius = radius {
            self.safeZoneRadius = radius
        }
        self.safeZoneUpdatedAt = Date()
        self.updatedAt = Date()
    }
    
    mutating func deleteSafeZone() {
        self.safeZoneName = nil
        self.safeZoneCenterLat = nil
        self.safeZoneCenterLon = nil
        self.safeZoneRadius = nil
        self.safeZoneIsActive = false
        self.safeZoneCreatedAt = nil
        self.safeZoneUpdatedAt = nil
        self.updatedAt = Date()
    }
}
