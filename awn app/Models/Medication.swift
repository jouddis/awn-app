//
//  Medication.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  Medication model with 3 frequency types
//

import Foundation
import CloudKit

enum MedicationFrequencyType: String, Codable {
    case interval = "INTERVAL"      // Every X days (1-10)
    case weekly = "WEEKLY"          // Specific days of week
    case asNeeded = "AS_NEEDED"     // PRN - no fixed schedule
    
    var displayName: String {
        switch self {
        case .interval: return "At Regular Intervals"
        case .weekly: return "On Specific Days of the Week"
        case .asNeeded: return "As Needed"
        }
    }
}

enum MedicationType: String, Codable {
    case capsule = "CAPSULE"
    case tablet = "TABLET"
    case liquid = "LIQUID"
    case topical = "TOPICAL"
    case other = "OTHER"
    
    var displayName: String {
        switch self {
        case .capsule: return "Capsule"
        case .tablet: return "Tablet"
        case .liquid: return "Liquid"
        case .topical: return "Topical"
        case .other: return "Other"
        }
    }
}

enum WeekDay: String, Codable, CaseIterable {
    case sunday = "SUN"
    case monday = "MON"
    case tuesday = "TUE"
    case wednesday = "WED"
    case thursday = "THU"
    case friday = "FRI"
    case saturday = "SAT"
    
    var displayName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
    
    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
}

struct Medication: Identifiable, Codable {
    let id: String
    let patientId: String
    
    var medicationName: String
    var medicationType: MedicationType
    var dosage: String              // "10mg", "2 pills", "5mL"
    var shape: String?              // Icon/color identifier
    var notes: String?
    
    // Frequency configuration
    var frequencyType: MedicationFrequencyType
    
    // For INTERVAL type
    var intervalDays: Int?          // 1-10 days
    var startDate: Date?            // When to start counting
    
    // For WEEKLY type
    var weekDays: [WeekDay]?        // Selected days
    
    // For AS_NEEDED type
    var maxDosesPerDay: Int?        // Safety limit
    
    // Common scheduling
    var scheduledTimes: [String]    // ["09:00", "21:00"] in HH:mm format
    
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initialization
    
    init(id: String = UUID().uuidString,
         patientId: String,
         medicationName: String,
         medicationType: MedicationType,
         dosage: String,
         shape: String? = nil,
         notes: String? = nil,
         frequencyType: MedicationFrequencyType,
         intervalDays: Int? = nil,
         startDate: Date? = nil,
         weekDays: [WeekDay]? = nil,
         maxDosesPerDay: Int? = nil,
         scheduledTimes: [String] = [],
         isActive: Bool = true,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.patientId = patientId
        self.medicationName = medicationName
        self.medicationType = medicationType
        self.dosage = dosage
        self.shape = shape
        self.notes = notes
        self.frequencyType = frequencyType
        self.intervalDays = intervalDays
        self.startDate = startDate
        self.weekDays = weekDays
        self.maxDosesPerDay = maxDosesPerDay
        self.scheduledTimes = scheduledTimes
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    var displayFrequency: String {
        switch frequencyType {
        case .interval:
            guard let days = intervalDays else { return "Every day" }
            return days == 1 ? "Every day" : "Every \(days) days"
        case .weekly:
            guard let days = weekDays, !days.isEmpty else { return "Weekly" }
            let dayNames = days.map { $0.displayName }.joined(separator: ", ")
            return dayNames
        case .asNeeded:
            if let maxDoses = maxDosesPerDay {
                return "As needed (max \(maxDoses)/day)"
            }
            return "As needed"
        }
    }
    
    var displayTimes: String {
        guard !scheduledTimes.isEmpty else { return "No times set" }
        return scheduledTimes.joined(separator: ", ")
    }
    
    var fullDisplayName: String {
        return "\(medicationName) \(dosage)"
    }
    
    // MARK: - CloudKit Conversion
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Constants.CloudKit.RecordType.medication)
        record["id"] = id as CKRecordValue
        
        let patientReference = CKRecord.Reference(
            recordID: CKRecord.ID(recordName: patientId),
            action: .none  // ← Change from .deleteSelf
        )
        record["patientReference"] = patientReference
        
        record["medicationName"] = medicationName as CKRecordValue
        record["medicationType"] = medicationType.rawValue as CKRecordValue
        record["dosage"] = dosage as CKRecordValue
        
        if let shape = shape {
            record["shape"] = shape as CKRecordValue
        }
        
        if let notes = notes {
            record["notes"] = notes as CKRecordValue
        }
        
        record["frequencyType"] = frequencyType.rawValue as CKRecordValue
        
        if let intervalDays = intervalDays {
            record["intervalDays"] = intervalDays as CKRecordValue
        }
        
        if let startDate = startDate {
            record["startDate"] = startDate as CKRecordValue
        }
        
        if let weekDays = weekDays {
            let weekDayStrings = weekDays.map { $0.rawValue }
            record["weekDays"] = weekDayStrings as CKRecordValue
        }
        
        if let maxDosesPerDay = maxDosesPerDay {
            record["maxDosesPerDay"] = maxDosesPerDay as CKRecordValue
        }
        
        record["scheduledTimes"] = scheduledTimes as CKRecordValue
        record["isActive"] = (isActive ? 1 : 0) as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["updatedAt"] = updatedAt as CKRecordValue
        
        return record
    }
    
    init?(from record: CKRecord) {
        guard let id = record["id"] as? String,
              let patientRef = record["patientReference"] as? CKRecord.Reference,
              let medicationName = record["medicationName"] as? String,
              let medicationTypeRaw = record["medicationType"] as? String,
              let medicationType = MedicationType(rawValue: medicationTypeRaw),
              let dosage = record["dosage"] as? String,
              let frequencyTypeRaw = record["frequencyType"] as? String,
              let frequencyType = MedicationFrequencyType(rawValue: frequencyTypeRaw),
              let scheduledTimes = record["scheduledTimes"] as? [String],
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        self.id = id
        self.patientId = patientRef.recordID.recordName
        self.medicationName = medicationName
        self.medicationType = medicationType
        self.dosage = dosage
        self.shape = record["shape"] as? String
        self.notes = record["notes"] as? String
        self.frequencyType = frequencyType
        
        self.intervalDays = record["intervalDays"] as? Int
        self.startDate = record["startDate"] as? Date
        
        if let weekDayStrings = record["weekDays"] as? [String] {
            self.weekDays = weekDayStrings.compactMap { WeekDay(rawValue: $0) }
        }
        
        self.maxDosesPerDay = record["maxDosesPerDay"] as? Int
        self.scheduledTimes = scheduledTimes
        
        let isActiveInt = record["isActive"] as? Int ?? 1
        self.isActive = isActiveInt == 1
        
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Scheduling Logic
    
    func shouldGenerateDoseForToday() -> Bool {
        let today = Date()
        
        switch frequencyType {
        case .interval:
            guard let days = intervalDays,
                  let start = startDate else { return false }
            
            let calendar = Calendar.current
            let daysSinceStart = calendar.dateComponents([.day], from: start, to: today).day ?? 0
            return daysSinceStart % days == 0
            
        case .weekly:
            guard let selectedDays = weekDays else { return false }
            
            let calendar = Calendar.current
            let weekdayIndex = calendar.component(.weekday, from: today) // 1 = Sunday
            let weekDayArray = WeekDay.allCases
            let todayWeekDay = weekDayArray[weekdayIndex - 1]
            
            return selectedDays.contains(todayWeekDay)
            
        case .asNeeded:
            return false // No automatic generation
        }
    }
}

