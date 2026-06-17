//
//  LocationSharingRequest.swift
//  awn app
//
//  Created by Joud Almashgari on 12/06/2026.
//

//
//  LocationSharingRequest.swift
//  awn app
//
//  Model for caregiver → patient location sharing requests
//

import Foundation
import CloudKit

// MARK: - Status

enum LocationRequestStatus: String, Codable {
    case pending   // Sent, awaiting patient response
    case accepted  // Patient accepted
    case declined  // Patient declined
    case revoked   // Patient revoked after accepting
}

// MARK: - Model

struct LocationSharingRequest: Identifiable, Codable {
    let id: String
    let caregiverId: String
    let caregiverName: String
    let patientId: String
    var status: LocationRequestStatus
    var requestedAt: Date
    var respondedAt: Date?

    init(
        id: String = UUID().uuidString,
        caregiverId: String,
        caregiverName: String,
        patientId: String,
        status: LocationRequestStatus = .pending,
        requestedAt: Date = Date(),
        respondedAt: Date? = nil
    ) {
        self.id = id
        self.caregiverId = caregiverId
        self.caregiverName = caregiverName
        self.patientId = patientId
        self.status = status
        self.requestedAt = requestedAt
        self.respondedAt = respondedAt
    }

    // MARK: - CloudKit Conversion (matches project pattern)

    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(
            recordType: Constants.CloudKit.RecordType.locationSharingRequest,
            recordID: recordID
        )
        record["id"]            = id as CKRecordValue
        record["caregiverId"]   = caregiverId as CKRecordValue
        record["caregiverName"] = caregiverName as CKRecordValue
        record["patientId"]     = patientId as CKRecordValue
        record["status"]        = status.rawValue as CKRecordValue
        record["requestedAt"]   = requestedAt as CKRecordValue

        if let respondedAt = respondedAt {
            record["respondedAt"] = respondedAt as CKRecordValue
        }
        return record
    }

    init?(from record: CKRecord) {
        guard
            let id            = record["id"] as? String,
            let caregiverId   = record["caregiverId"] as? String,
            let caregiverName = record["caregiverName"] as? String,
            let patientId     = record["patientId"] as? String,
            let statusRaw     = record["status"] as? String,
            let status        = LocationRequestStatus(rawValue: statusRaw),
            let requestedAt   = record["requestedAt"] as? Date
        else { return nil }

        self.id            = id
        self.caregiverId   = caregiverId
        self.caregiverName = caregiverName
        self.patientId     = patientId
        self.status        = status
        self.requestedAt   = requestedAt
        self.respondedAt   = record["respondedAt"] as? Date
    }
}
