//
//  CareGiver.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  Caregiver profile model
//

import Foundation
import CloudKit

struct Caregiver: Identifiable, Codable {
    let id: String
    let userId: String // Reference to AppUser
    var name: String
    var relationship: String
    var phoneNumber: String?
    var linkedPatientId: String? // 1:1 relationship
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initialization
    
    init(id: String = UUID().uuidString,
         userId: String,
         name: String,
         relationship: String,
         phoneNumber: String? = nil,
         linkedPatientId: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.name = name
        self.relationship = relationship
        self.phoneNumber = phoneNumber
        self.linkedPatientId = linkedPatientId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - CloudKit Conversion
    
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: Constants.CloudKit.RecordType.caregiver, recordID: recordID)
        record["id"] = id as CKRecordValue
        
        // User reference
        let userReference = CKRecord.Reference(
            recordID: CKRecord.ID(recordName: userId),
            action: .none  // ← Change from .deleteSelf
        )
        record["userReference"] = userReference
        
        record["name"] = name as CKRecordValue
        record["relationship"] = relationship as CKRecordValue
        
        if let phoneNumber = phoneNumber {
            record["phoneNumber"] = phoneNumber as CKRecordValue
        }
        
        if let linkedPatientId = linkedPatientId {
            record["linkedPatientId"] = linkedPatientId as CKRecordValue
        }
        
        record["createdAt"] = createdAt as CKRecordValue
        record["updatedAt"] = updatedAt as CKRecordValue
        
        return record
    }
    
    init?(from record: CKRecord) {
        guard let id = record["id"] as? String,
              let userRef = record["userReference"] as? CKRecord.Reference,
              let name = record["name"] as? String,
              let relationship = record["relationship"] as? String,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        self.id = id
        self.userId = userRef.recordID.recordName
        self.name = name
        self.relationship = relationship
        self.phoneNumber = record["phoneNumber"] as? String
        self.linkedPatientId = record["linkedPatientId"] as? String
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

