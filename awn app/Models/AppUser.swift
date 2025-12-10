//
//  AppUser.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  User model for authentication
//

import Foundation
import CloudKit

struct AppUser: Identifiable, Codable {
    let id: String
    let appleUserID: String
    var email: String?
    var fullName: String?
    // REMOVED: var role: String - No longer needed since only caregivers have accounts
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initialization
    
    init(id: String = UUID().uuidString,
         appleUserID: String,
         email: String? = nil,
         fullName: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.appleUserID = appleUserID
        self.email = email
        self.fullName = fullName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - CloudKit Conversion
    
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: Constants.CloudKit.RecordType.appUser, recordID: recordID)
        record["id"] = id as CKRecordValue
        record["appleUserID"] = appleUserID as CKRecordValue
        
        if let email = email {
            record["email"] = email as CKRecordValue
        }
        
        if let fullName = fullName {
            record["fullName"] = fullName as CKRecordValue
        }
        
        record["createdAt"] = createdAt as CKRecordValue
        record["updatedAt"] = updatedAt as CKRecordValue
        
        return record
    }
    
    init?(from record: CKRecord) {
        guard let id = record["id"] as? String,
              let appleUserID = record["appleUserID"] as? String,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        self.id = id
        self.appleUserID = appleUserID
        self.email = record["email"] as? String
        self.fullName = record["fullName"] as? String
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
