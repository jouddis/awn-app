//
//  CloudKitManager.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  Complete CloudKit manager with all Phase 2 operations
//

import Foundation
import CloudKit
import Combine

class CloudKitManager {
    static let shared = CloudKitManager()
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let publicDatabase: CKDatabase
    
    private init() {
        self.container = Constants.CloudKit.container
        self.privateDatabase = container.privateCloudDatabase
        self.publicDatabase = container.publicCloudDatabase
    }
    
    // MARK: - Generic CRUD Operations
    
    func save<T>(_ item: T, completion: @escaping (Result<T, Error>) -> Void) where T: Identifiable {
        // This would need protocol conformance for toCKRecord
        // For now, we'll use specific methods below
    }
    
    func fetch<T>(recordID: CKRecord.ID, as type: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        privateDatabase.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let record = record else {
                completion(.failure(NSError(domain: "CloudKitManager", code: -1)))
                return
            }
            
            // Would need protocol conformance for init(from: CKRecord)
            // Using specific methods below
        }
    }
    
    func delete(recordID: CKRecord.ID, completion: @escaping (Result<Void, Error>) -> Void) {
        privateDatabase.delete(withRecordID: recordID) { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - AppUser Operations (Phase 1)
    
    func fetchUser(byAppleUserID appleUserID: String, completion: @escaping (Result<AppUser, Error>) -> Void) {
        let predicate = NSPredicate(format: "appleUserID == %@", appleUserID)
        let query = CKQuery(recordType: Constants.CloudKit.RecordType.appUser, predicate: predicate)
        
        privateDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let record = records?.first,
                  let user = AppUser(from: record) else {
                let error = NSError(domain: "CloudKitManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
                completion(.failure(error))
                return
            }
            
            completion(.success(user))
        }
    }
    
    func saveUser(_ user: AppUser, completion: @escaping (Result<AppUser, Error>) -> Void) {
        let record = user.toCKRecord()
        
        // Use modify operation with save policy to overwrite if exists
        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let savedRecord = savedRecords?.first,
                  let savedUser = AppUser(from: savedRecord) else {
                completion(.failure(NSError(domain: "CloudKitManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse saved user"])))
                return
            }
            
            completion(.success(savedUser))
        }
        
        privateDatabase.add(operation)
    }
    
    // MARK: - Caregiver Operations (Phase 1)
    
    func fetchCaregiver(byUserID userID: String, completion: @escaping (Result<Caregiver, Error>) -> Void) {
        let userReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: userID), action: .none)
        let predicate = NSPredicate(format: "userReference == %@", userReference)
        let query = CKQuery(recordType: Constants.CloudKit.RecordType.caregiver, predicate: predicate)
        
        privateDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let record = records?.first,
                  let caregiver = Caregiver(from: record) else {
                let error = NSError(domain: "CloudKitManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Caregiver not found"])
                completion(.failure(error))
                return
            }
            
            completion(.success(caregiver))
        }
    }
    
    func saveCaregiver(_ caregiver: Caregiver, completion: @escaping (Result<Caregiver, Error>) -> Void) {
        let record = caregiver.toCKRecord()
        
        // Use modify operation with save policy to overwrite if exists
        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys  // Only update changed fields
        operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let savedRecord = savedRecords?.first,
                  let savedCaregiver = Caregiver(from: savedRecord) else {
                completion(.failure(NSError(domain: "CloudKitManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse saved caregiver"])))
                return
            }
            
            completion(.success(savedCaregiver))
        }
        
        privateDatabase.add(operation)
    }
    
    // MARK: - Patient Operations
    
    func savePatient(_ patient: Patient, completion: @escaping (Result<Patient, Error>) -> Void) {
        let record = patient.toCKRecord()
        
        // Use modify operation with save policy to overwrite if exists
        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let savedRecord = savedRecords?.first,
                  let savedPatient = Patient(from: savedRecord) else {
                completion(.failure(NSError(domain: "CloudKitManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse saved patient"])))
                return
            }
            
            completion(.success(savedPatient))
        }
        
        privateDatabase.add(operation)
    }
    
    func fetchPatient(byID id: String, completion: @escaping (Result<Patient, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: id)
        
        privateDatabase.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let record = record,
                  let patient = Patient(from: record) else {
                completion(.failure(NSError(domain: "CloudKitManager", code: -1)))
                return
            }
            
            completion(.success(patient))
        }
    }
    
    func fetchPatient(byUserID userID: String, completion: @escaping (Result<Patient, Error>) -> Void) {
        // Create reference to AppUser
        let userReference = CKRecord.Reference(
            recordID: CKRecord.ID(recordName: userID),
            action: .none
        )
        
        // Query by userReference field (not userId string)
        let predicate = NSPredicate(format: "userReference == %@", userReference)
        let query = CKQuery(recordType: Constants.CloudKit.RecordType.patient, predicate: predicate)
        
        privateDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let record = records?.first,
                  let patient = Patient(from: record) else {
                completion(.failure(NSError(domain: "CloudKitManager", code: -1)))
                return
            }
            
            completion(.success(patient))
        }
    }
    
    func updatePatientSafeZone(patientID: String,
                              name: String,
                              centerLat: Double,
                              centerLon: Double,
                              radius: Double,
                              completion: @escaping (Result<Patient, Error>) -> Void) {
        fetchPatient(byID: patientID) { [weak self] result in
            switch result {
            case .success(var patient):
                patient.setSafeZone(name: name, centerLat: centerLat, centerLon: centerLon, radius: radius)
                self?.savePatient(patient, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func deletePatientSafeZone(patientID: String, completion: @escaping (Result<Patient, Error>) -> Void) {
        fetchPatient(byID: patientID) { [weak self] result in
            switch result {
            case .success(var patient):
                patient.deleteSafeZone()
                self?.savePatient(patient, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - AlertEvent Operations
    
    func saveAlertEvent(_ alert: AlertEvent, completion: @escaping (Result<AlertEvent, Error>) -> Void) {
        let record = alert.toCKRecord()
        
        privateDatabase.save(record) { savedRecord, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let savedRecord = savedRecord,
                  let savedAlert = AlertEvent(from: savedRecord) else {
                completion(.failure(NSError(domain: "CloudKitManager", code: -1)))
                return
            }
            
            completion(.success(savedAlert))
        }
    }
    
    func fetchAlerts(for patientID: String,
                    unreadOnly: Bool = false,
                    completion: @escaping (Result<[AlertEvent], Error>) -> Void) {
        let patientRef = CKRecord.Reference(recordID: CKRecord.ID(recordName: patientID), action: .none)
        
        var predicates: [NSPredicate] = [NSPredicate(format: "patientReference == %@", patientRef)]
        
        if unreadOnly {
            predicates.append(NSPredicate(format: "isRead == 0"))
        }
        
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let query = CKQuery(recordType: Constants.CloudKit.RecordType.alertEvent, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        privateDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let alerts = records?.compactMap { AlertEvent(from: $0) } ?? []
            completion(.success(alerts))
        }
    }
    
    func fetchPendingConfirmations(for patientID: String, completion: @escaping (Result<[AlertEvent], Error>) -> Void) {
        let patientRef = CKRecord.Reference(recordID: CKRecord.ID(recordName: patientID), action: .none)
        
        let predicates = [
            NSPredicate(format: "patientReference == %@", patientRef),
            NSPredicate(format: "confirmationStatus == %@", ConfirmationStatus.pending.rawValue)
        ]
        
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let query = CKQuery(recordType: Constants.CloudKit.RecordType.alertEvent, predicate: predicate)
        
        privateDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let alerts = records?.compactMap { AlertEvent(from: $0) } ?? []
            completion(.success(alerts))
        }
    }
    
    func markAlertAsRead(alertID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: alertID)
        
        privateDatabase.fetch(withRecordID: recordID) { [weak self] record, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let record = record else {
                completion(.failure(NSError(domain: "CloudKitManager", code: -1)))
                return
            }
            
            record["isRead"] = 1 as CKRecordValue
            
            self?.privateDatabase.save(record) { _, saveError in
                if let saveError = saveError {
                    completion(.failure(saveError))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func confirmAlertAccompanied(alertID: String, completion: @escaping (Result<AlertEvent, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: alertID)
        
        privateDatabase.fetch(withRecordID: recordID) { [weak self] record, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let record = record else {
                completion(.failure(NSError(domain: "CloudKitManager", code: -1)))
                return
            }
            
            record["confirmationStatus"] = ConfirmationStatus.accompanied.rawValue as CKRecordValue
            record["confirmedAt"] = Date() as CKRecordValue
            
            self?.privateDatabase.save(record) { savedRecord, saveError in
                if let saveError = saveError {
                    completion(.failure(saveError))
                    return
                }
                
                guard let savedRecord = savedRecord,
                      let alert = AlertEvent(from: savedRecord) else {
                    completion(.failure(NSError(domain: "CloudKitManager", code: -1)))
                    return
                }
                
                completion(.success(alert))
            }
        }
    }
    
    func confirmAlertWandering(alertID: String, completion: @escaping (Result<AlertEvent, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: alertID)
        
        privateDatabase.fetch(withRecordID: recordID) { [weak self] record, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let record = record else {
                completion(.failure(NSError(domain: "CloudKitManager", code: -1)))
                return
            }
            
            record["confirmationStatus"] = ConfirmationStatus.wandering.rawValue as CKRecordValue
            record["confirmedAt"] = Date() as CKRecordValue
            
            self?.privateDatabase.save(record) { savedRecord, saveError in
                if let saveError = saveError {
                    completion(.failure(saveError))
                    return
                }
                
                guard let savedRecord = savedRecord,
                      let alert = AlertEvent(from: savedRecord) else {
                    completion(.failure(NSError(domain: "CloudKitManager", code: -1)))
                    return
                }
                
                completion(.success(alert))
            }
        }
    }
    
    // MARK: - Medication Operations
    
    func saveMedication(_ medication: Medication, completion: @escaping (Result<Medication, Error>) -> Void) {
        let record = medication.toCKRecord()
        
        privateDatabase.save(record) { savedRecord, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let savedRecord = savedRecord,
                  let savedMedication = Medication(from: savedRecord) else {
                completion(.failure(NSError(domain: "CloudKitManager", code: -1)))
                return
            }
            
            completion(.success(savedMedication))
        }
    }
    
    func fetchMedications(for patientID: String,
                         activeOnly: Bool = true,
                         completion: @escaping (Result<[Medication], Error>) -> Void) {
        let patientRef = CKRecord.Reference(recordID: CKRecord.ID(recordName: patientID), action: .none)
        
        var predicates: [NSPredicate] = [NSPredicate(format: "patientReference == %@", patientRef)]
        
        if activeOnly {
            predicates.append(NSPredicate(format: "isActive == 1"))
        }
        
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let query = CKQuery(recordType: Constants.CloudKit.RecordType.medication, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "medicationName", ascending: true)]
        
        privateDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let medications = records?.compactMap { Medication(from: $0) } ?? []
            completion(.success(medications))
        }
    }
    
    func archiveMedication(medicationID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: medicationID)
        
        privateDatabase.fetch(withRecordID: recordID) { [weak self] record, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let record = record else {
                completion(.failure(NSError(domain: "CloudKitManager", code: -1)))
                return
            }
            
            record["isActive"] = 0 as CKRecordValue
            record["updatedAt"] = Date() as CKRecordValue
            
            self?.privateDatabase.save(record) { _, saveError in
                if let saveError = saveError {
                    completion(.failure(saveError))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    // MARK: - MedicationDoseLog Operations
    
    func saveDoseLog(_ doseLog: MedicationDoseLog, completion: @escaping (Result<MedicationDoseLog, Error>) -> Void) {
        let record = doseLog.toCKRecord()
        
        privateDatabase.save(record) { savedRecord, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let savedRecord = savedRecord,
                  let savedLog = MedicationDoseLog(from: savedRecord) else {
                completion(.failure(NSError(domain: "CloudKitManager", code: -1)))
                return
            }
            
            completion(.success(savedLog))
        }
    }
    
    func fetchDoseLogs(for patientID: String,
                      date: Date,
                      completion: @escaping (Result<[MedicationDoseLog], Error>) -> Void) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let patientRef = CKRecord.Reference(recordID: CKRecord.ID(recordName: patientID), action: .none)
        
        let predicates = [
            NSPredicate(format: "patientReference == %@", patientRef),
            NSPredicate(format: "scheduledDateTime >= %@", startOfDay as NSDate),
            NSPredicate(format: "scheduledDateTime < %@", endOfDay as NSDate)
        ]
        
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let query = CKQuery(recordType: Constants.CloudKit.RecordType.medicationDoseLog, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "scheduledDateTime", ascending: true)]
        
        privateDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let logs = records?.compactMap { MedicationDoseLog(from: $0) } ?? []
            completion(.success(logs))
        }
    }
    
    func markDoseAsTaken(doseLogID: String,
                        takenTime: Date = Date(),
                        notes: String? = nil,
                        completion: @escaping (Result<MedicationDoseLog, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: doseLogID)
        
        privateDatabase.fetch(withRecordID: recordID) { [weak self] record, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let record = record else {
                completion(.failure(NSError(domain: "CloudKitManager", code: -1)))
                return
            }
            
            record["status"] = DoseStatus.taken.rawValue as CKRecordValue
            record["takenDateTime"] = takenTime as CKRecordValue
            record["updatedAt"] = Date() as CKRecordValue
            
            if let notes = notes {
                record["notes"] = notes as CKRecordValue
            }
            
            self?.privateDatabase.save(record) { savedRecord, saveError in
                if let saveError = saveError {
                    completion(.failure(saveError))
                    return
                }
                
                guard let savedRecord = savedRecord,
                      let log = MedicationDoseLog(from: savedRecord) else {
                    completion(.failure(NSError(domain: "CloudKitManager", code: -1)))
                    return
                }
                
                completion(.success(log))
            }
        }
    }
    
    // MARK: - Wandering Statistics
    
    func fetchWanderingStats(for patientID: String,
                           startDate: Date,
                           endDate: Date,
                           completion: @escaping (Result<[AlertEvent], Error>) -> Void) {
        let patientRef = CKRecord.Reference(recordID: CKRecord.ID(recordName: patientID), action: .none)
        
        let predicates = [
            NSPredicate(format: "patientReference == %@", patientRef),
            NSPredicate(format: "alertType == %@", AlertType.geofenceExit.rawValue),
            NSPredicate(format: "timestamp >= %@", startDate as NSDate),
            NSPredicate(format: "timestamp < %@", endDate as NSDate)
        ]
        
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let query = CKQuery(recordType: Constants.CloudKit.RecordType.alertEvent, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        privateDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let alerts = records?.compactMap { AlertEvent(from: $0) } ?? []
            completion(.success(alerts))
        }
    }
}

