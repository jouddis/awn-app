//
//  WatchCloudKitManager.swift
//  awn app
//
//  Created by Joud Almashgari on 11/12/2025.
//
//  Simplified CloudKit manager for watchOS
//  Only handles AlertEvent operations
//
//
//  WatchCloudKitManager.swift
//  awn app
//
//  Created by Joud Almashgari on 11/12/2025.
//
//  Simplified CloudKit manager for watchOS
//  Handles Patient fetching and AlertEvent operations
//

import Foundation
import CloudKit

class WatchCloudKitManager {
    static let shared = WatchCloudKitManager()
    
    let container: CKContainer
    let privateDatabase: CKDatabase
    
    private init() {
        self.container = Constants.CloudKit.container
        self.privateDatabase = container.privateCloudDatabase
    }
    
    // MARK: - Patient Operations (Read Only)
    
    /// Fetch patient by ID (legacy method - kept for compatibility)
    func fetchPatient(byID id: String, completion: @escaping (Result<Patient, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: id)
        
        privateDatabase.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let record = record,
                  let patient = Patient(from: record) else {
                completion(.failure(NSError(domain: "WatchCloudKitManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode patient"])))
                return
            }
            
            completion(.success(patient))
        }
    }
    
    /// Fetch patient by caregiver ID (RECOMMENDED - avoids cached ID issues)
    func fetchPatientForCaregiver(caregiverID: String, completion: @escaping (Result<Patient, Error>) -> Void) {
        print("🔍 Fetching patient for caregiver: \(caregiverID)")
        
        let predicate = NSPredicate(format: "caregiverId == %@", caregiverID)
        let query = CKQuery(recordType: Constants.CloudKit.RecordType.patient, predicate: predicate)
        
        // Sort by creation date (most recent first)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        privateDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                print("❌ Query failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let records = records, !records.isEmpty else {
                print("❌ No patient found for caregiver")
                let error = NSError(domain: "WatchCloudKitManager",
                                  code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "No patient found for this caregiver"])
                completion(.failure(error))
                return
            }
            
            guard let record = records.first,
                  let patient = Patient(from: record) else {
                print("❌ Failed to decode patient from record")
                let error = NSError(domain: "WatchCloudKitManager",
                                  code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "Failed to decode patient"])
                completion(.failure(error))
                return
            }
            
            print("✅ Patient found: \(patient.name)")
            print("   Patient ID: \(patient.id)")
            print("   Has safe zone: \(patient.hasSafeZone)")
            
            completion(.success(patient))
        }
    }
    
    /// Fetch the current patient (queries for any patient in the system)
    /// Use this as a fallback when caregiver ID is unknown
    func fetchCurrentPatient(completion: @escaping (Result<Patient, Error>) -> Void) {
        print("🔍 Fetching any available patient...")
        
        let predicate = NSPredicate(value: true) // Match all
        let query = CKQuery(recordType: Constants.CloudKit.RecordType.patient, predicate: predicate)
        
        // Sort by most recently updated
        query.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        
        privateDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                print("❌ Query failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let records = records, !records.isEmpty else {
                print("❌ No patients found in CloudKit")
                let error = NSError(domain: "WatchCloudKitManager",
                                  code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "No patients found"])
                completion(.failure(error))
                return
            }
            
            guard let record = records.first,
                  let patient = Patient(from: record) else {
                print("❌ Failed to decode patient")
                let error = NSError(domain: "WatchCloudKitManager",
                                  code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "Failed to decode patient"])
                completion(.failure(error))
                return
            }
            
            print("✅ Patient found: \(patient.name)")
            print("   Patient ID: \(patient.id)")
            
            completion(.success(patient))
        }
    }
    
    // MARK: - AlertEvent Operations
    
    func saveAlertEvent(_ alert: AlertEvent, completion: @escaping (Result<AlertEvent, Error>) -> Void) {
        let record = alert.toCKRecord()
        
        privateDatabase.save(record) { savedRecord, error in
            if let error = error {
                print("❌ Failed to save alert: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let savedRecord = savedRecord,
                  let savedAlert = AlertEvent(from: savedRecord) else {
                print("❌ Failed to decode saved alert")
                let error = NSError(domain: "WatchCloudKitManager",
                                  code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "Failed to decode saved alert"])
                completion(.failure(error))
                return
            }
            
            print("✅ Alert saved: \(savedAlert.alertType)")
            completion(.success(savedAlert))
        }
    }
    
    // MARK: - Fetch Multiple Alerts (for testing/debugging)
    
    func fetchAlertsForPatient(patientID: String, limit: Int = 10, completion: @escaping (Result<[AlertEvent], Error>) -> Void) {
        print("🔍 Fetching alerts for patient: \(patientID)")
        
        let predicate = NSPredicate(format: "patientId == %@", patientID)
        let query = CKQuery(recordType: Constants.CloudKit.RecordType.alertEvent, predicate: predicate)
        
        // Sort by most recent
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        privateDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                print("❌ Failed to fetch alerts: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let records = records else {
                completion(.success([]))
                return
            }
            
            let alerts = records.compactMap { AlertEvent(from: $0) }
            print("✅ Fetched \(alerts.count) alerts")
            
            completion(.success(Array(alerts.prefix(limit))))
        }
    }
}
