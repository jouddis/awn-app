//
//  CloudKitManager+LocationSharing.swift
//  awn app
//
//  Created by Joud Almashgari on 12/06/2026.
//
//
//  CloudKitManager+LocationSharing.swift
//  awn app
//
//  Created by Joud Almashgari on 12/06/2026.
//

//
//  CloudKitManager+LocationSharing.swift
//  awn app
//
//  Extension on CloudKitManager for location sharing request operations.
//  Drop this file into the Services/ folder — no changes to CloudKitManager.swift needed.
//

import Foundation
import CloudKit

extension CloudKitManager {

    // MARK: - Save Request (Caregiver sends)

    func saveLocationRequest(
        _ request: LocationSharingRequest,
        completion: @escaping (Result<LocationSharingRequest, Error>) -> Void
    ) {
        let record = request.toCKRecord()
        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.modifyRecordsCompletionBlock = { savedRecords, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to save location request: \(error)")
                    completion(.failure(error))
                } else {
                    print("✅ Location request saved")
                    completion(.success(request))
                }
            }
        }
        privateDatabase.add(operation)
    }

    // MARK: - Fetch Pending Requests for Patient

    func fetchPendingRequestsForPatient(
        patientId: String,
        completion: @escaping (Result<[LocationSharingRequest], Error>) -> Void
    ) {
        // NOTE: Only patientId is used in the predicate.
        // 'status' is NOT included here because it requires a queryable index
        // in CloudKit Dashboard. We filter to .pending in memory after fetch.
        let predicate = NSPredicate(format: "patientId == %@", patientId)
        let query = CKQuery(
            recordType: Constants.CloudKit.RecordType.locationSharingRequest,
            predicate: predicate
        )
        query.sortDescriptors = [NSSortDescriptor(key: "requestedAt", ascending: false)]

        privateDatabase.perform(query, inZoneWith: nil) { records, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to fetch pending requests: \(error)")
                    completion(.failure(error))
                    return
                }
                // Filter to pending only — done in memory to avoid queryable index requirement
                let requests = (records ?? [])
                    .compactMap { LocationSharingRequest(from: $0) }
                    .filter { $0.status == .pending }
                print("✅ Found \(requests.count) pending location requests")
                completion(.success(requests))
            }
        }
    }

    // MARK: - Fetch Request Status (Caregiver polls)

    func fetchLocationRequestStatus(
        caregiverId: String,
        patientId: String,
        completion: @escaping (Result<LocationSharingRequest?, Error>) -> Void
    ) {
        let predicate = NSPredicate(
            format: "caregiverId == %@ AND patientId == %@",
            caregiverId,
            patientId
        )
        let query = CKQuery(
            recordType: Constants.CloudKit.RecordType.locationSharingRequest,
            predicate: predicate
        )
        query.sortDescriptors = [NSSortDescriptor(key: "requestedAt", ascending: false)]

        privateDatabase.perform(query, inZoneWith: nil) { records, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                // Return most recent request
                let request = records?.first.flatMap { LocationSharingRequest(from: $0) }
                completion(.success(request))
            }
        }
    }

    // MARK: - Update Request Status (Patient responds)

    func updateLocationRequestStatus(
        requestId: String,
        newStatus: LocationRequestStatus,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let recordID = CKRecord.ID(recordName: requestId)

        privateDatabase.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let record = record else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(
                        domain: "CloudKitManager",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "Request record not found"]
                    )))
                }
                return
            }

            record["status"]      = newStatus.rawValue as CKRecordValue
            record["respondedAt"] = Date() as CKRecordValue

            self.privateDatabase.save(record) { _, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Failed to update request status: \(error)")
                        completion(.failure(error))
                    } else {
                        print("✅ Request status updated to: \(newStatus.rawValue)")
                        completion(.success(()))
                    }
                }
            }
        }
    }
}
