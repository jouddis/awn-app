//
//  MedicationDoseLog.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  Daily medication dose tracking and compliance
//

import Foundation
import CloudKit

enum DoseStatus: String, Codable {
    case scheduled = "SCHEDULED"
    case taken = "TAKEN"
    case missed = "MISSED"
    
    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .taken: return "Taken"
        case .missed: return "Missed"
        }
    }
    
    var emoji: String {
        switch self {
        case .scheduled: return "⏰"
        case .taken: return "✓"
        case .missed: return "✗"
        }
    }
    
    var color: String {
        switch self {
        case .scheduled: return "gray"
        case .taken: return "green"
        case .missed: return "red"
        }
    }
}

struct MedicationDoseLog: Identifiable, Codable {
    let id: String
    let medicationId: String
    let patientId: String
    
    let scheduledDateTime: Date
    var status: DoseStatus
    var takenDateTime: Date?
    var confirmedBy: String              // "CAREGIVER"
    var notes: String?
    
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initialization
    
    init(id: String = UUID().uuidString,
         medicationId: String,
         patientId: String,
         scheduledDateTime: Date,
         status: DoseStatus = .scheduled,
         takenDateTime: Date? = nil,
         confirmedBy: String = "CAREGIVER",
         notes: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.medicationId = medicationId
        self.patientId = patientId
        self.scheduledDateTime = scheduledDateTime
        self.status = status
        self.takenDateTime = takenDateTime
        self.confirmedBy = confirmedBy
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    var isPastDue: Bool {
        guard status == .scheduled else { return false }
        return scheduledDateTime < Date()
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(scheduledDateTime)
    }
    
    var displayTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: scheduledDateTime)
    }
    
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: scheduledDateTime)
    }
    
    var displayDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: scheduledDateTime)
    }
    
    // MARK: - CloudKit Conversion
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Constants.CloudKit.RecordType.medicationDoseLog)
        record["id"] = id as CKRecordValue
        
        let medicationReference = CKRecord.Reference(
            recordID: CKRecord.ID(recordName: medicationId),
            action: .none  // ← Change from .deleteSelf
        )
        record["medicationReference"] = medicationReference
        
        let patientReference = CKRecord.Reference(
            recordID: CKRecord.ID(recordName: patientId),
            action: .none  // ← Change from .deleteSelf
        )
        record["patientReference"] = patientReference
        
        record["scheduledDateTime"] = scheduledDateTime as CKRecordValue
        record["status"] = status.rawValue as CKRecordValue
        
        if let takenDateTime = takenDateTime {
            record["takenDateTime"] = takenDateTime as CKRecordValue
        }
        
        record["confirmedBy"] = confirmedBy as CKRecordValue
        
        if let notes = notes {
            record["notes"] = notes as CKRecordValue
        }
        
        record["createdAt"] = createdAt as CKRecordValue
        record["updatedAt"] = updatedAt as CKRecordValue
        
        return record
    }
    
    init?(from record: CKRecord) {
        guard let id = record["id"] as? String,
              let medicationRef = record["medicationReference"] as? CKRecord.Reference,
              let patientRef = record["patientReference"] as? CKRecord.Reference,
              let scheduledDateTime = record["scheduledDateTime"] as? Date,
              let statusRaw = record["status"] as? String,
              let status = DoseStatus(rawValue: statusRaw),
              let confirmedBy = record["confirmedBy"] as? String,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        self.id = id
        self.medicationId = medicationRef.recordID.recordName
        self.patientId = patientRef.recordID.recordName
        self.scheduledDateTime = scheduledDateTime
        self.status = status
        self.takenDateTime = record["takenDateTime"] as? Date
        self.confirmedBy = confirmedBy
        self.notes = record["notes"] as? String
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Helper Methods
    
    mutating func markAsTaken(at time: Date = Date(), notes: String? = nil) {
        self.status = .taken
        self.takenDateTime = time
        self.updatedAt = Date()
        if let notes = notes {
            self.notes = notes
        }
    }
    
    mutating func markAsMissed() {
        self.status = .missed
        self.updatedAt = Date()
    }
    
    mutating func reschedule(to newTime: Date) {
        // Only reschedule if not yet taken
        guard status == .scheduled else { return }
        // Note: In real implementation, we'd create a new log entry
        // For simplicity, we're just updating the time here
    }
}

// MARK: - Compliance Statistics

struct MedicationCompliance {
    let totalScheduled: Int
    let totalTaken: Int
    let totalMissed: Int
    
    var complianceRate: Double {
        guard totalScheduled > 0 else { return 0.0 }
        return Double(totalTaken) / Double(totalScheduled) * 100.0
    }
    
    var compliancePercentage: String {
        return String(format: "%.0f%%", complianceRate)
    }
    
    init(logs: [MedicationDoseLog]) {
        self.totalScheduled = logs.count
        self.totalTaken = logs.filter { $0.status == .taken }.count
        self.totalMissed = logs.filter { $0.status == .missed }.count
    }
}

