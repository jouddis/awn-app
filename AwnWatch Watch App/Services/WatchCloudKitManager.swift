//
//  WatchCloudKitManager.swift
//  awn app
//
//  Created by Joud Almashgari on 11/12/2025.
//
//  Simplified CloudKit manager for watchOS
//  Only handles AlertEvent operations
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
    
    func fetchPatient(byID id: String, completion: @escaping (Result<Patient, Error>) -> Void) {
        let recordID = CKRecord.ID(recordName: id)
        
        privateDatabase.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let record = record,
                  let patient = Patient(from: record) else {
                completion(.failure(NSError(domain: "WatchCloudKitManager", code: -1)))
                return
            }
            
            completion(.success(patient))
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
                completion(.failure(NSError(domain: "WatchCloudKitManager", code: -1)))
                return
            }
            
            completion(.success(savedAlert))
        }
    }
}

