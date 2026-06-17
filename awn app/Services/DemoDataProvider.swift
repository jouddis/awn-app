//
//  DemoDataProvider.swift
//  awn app
//
//  Created by Joud Almashgari on 13/06/2026.
//

//
//  DemoDataProvider.swift
//  awn app
//
//  Provides fully synthetic demo data for guest mode.
//  No CloudKit reads/writes — everything lives in memory.
//
//
//  DemoDataProvider.swift
//  awn app
//
//  Provides fully synthetic demo data for guest mode.
//  No CloudKit reads/writes — everything lives in memory.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Demo Session

/// Singleton that holds the active demo session.
/// Populated once when guest mode starts, cleared on sign-in.
class DemoSession: ObservableObject {
    static let shared = DemoSession()
    private init() {}

    @Published var isActive: Bool = false

    let caregiver = DemoDataProvider.caregiver
    let patient   = DemoDataProvider.patient
    let alerts    = DemoDataProvider.alerts
    let medications = DemoDataProvider.medications
    let safeZone  = DemoDataProvider.safeZone

    func activate() { isActive = true }
    func deactivate() { isActive = false }
}

// MARK: - Provider

enum DemoDataProvider {

    // MARK: Caregiver
    static let caregiver = Caregiver(
        id:              "DEMO-CAREGIVER-001",
        userId:          "DEMO-USER-001",
        name:            "Joud (Demo)",
        relationship:    "Daughter",
        linkedPatientId: "DEMO-PATIENT-001",
        createdAt:       Date(),
        updatedAt:       Date()
    )

    // MARK: Patient
    static let patient = Patient(
        id:                  "DEMO-PATIENT-001",
        name:                "Fatimah Al-Qahtani",
        dateOfBirth:         Calendar.current.date(byAdding: .year, value: -72, to: Date()),
        caregiverId:         "DEMO-CAREGIVER-001",
        watchDeviceID:       "DEMO-WATCH-001",
        watchPairedDate:     Calendar.current.date(byAdding: .day, value: -14, to: Date()),
        safeZoneName:        "Home",
        safeZoneCenterLat:   24.7136,
        safeZoneCenterLon:   46.6753,
        safeZoneRadius:      250.0,
        safeZoneIsActive:    true,
        safeZoneCreatedAt:   Calendar.current.date(byAdding: .day, value: -14, to: Date()),
        safeZoneUpdatedAt:   Calendar.current.date(byAdding: .day, value: -2, to: Date()),
        lastKnownLatitude:   24.7136,
        lastKnownLongitude:  46.6753,
        lastLocationTimestamp: Calendar.current.date(byAdding: .minute, value: -8, to: Date()),
        createdAt:           Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
        updatedAt:           Calendar.current.date(byAdding: .minute, value: -8, to: Date()) ?? Date()
    )

    // MARK: Safe Zone summary (for display without patient object)
    static let safeZone = (
        name:   "Home",
        lat:    24.7136,
        lon:    46.6753,
        radius: 250.0
    )

    // MARK: Alerts
    static let alerts: [AlertEvent] = [
        AlertEvent(
            id:                  "DEMO-ALERT-001",
            patientId:           "DEMO-PATIENT-001",
            alertType:           .geofenceExit,
            timestamp:           Calendar.current.date(byAdding: .hour, value: -3, to: Date()) ?? Date(),
            latitude:            24.7200,
            longitude:           46.6830,
            isRead:              true,
            requiresConfirmation: true,
            confirmationStatus:  .wandering,
            confirmedAt:         Calendar.current.date(byAdding: .hour, value: -2, to: Date()),
            createdAt:           Calendar.current.date(byAdding: .hour, value: -3, to: Date()) ?? Date()
        ),
        AlertEvent(
            id:                  "DEMO-ALERT-002",
            patientId:           "DEMO-PATIENT-001",
            alertType:           .geofenceEntry,
            timestamp:           Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
            latitude:            24.7136,
            longitude:           46.6753,
            isRead:              true,
            requiresConfirmation: false,
            confirmationStatus:  .notApplicable,
            createdAt:           Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
        ),
        AlertEvent(
            id:                  "DEMO-ALERT-003",
            patientId:           "DEMO-PATIENT-001",
            alertType:           .fallDetected,
            timestamp:           Calendar.current.date(byAdding: .minute, value: -45, to: Date()) ?? Date(),
            latitude:            24.7136,
            longitude:           46.6753,
            isRead:              false,
            requiresConfirmation: false,
            confirmationStatus:  .notApplicable,
            createdAt:           Calendar.current.date(byAdding: .minute, value: -45, to: Date()) ?? Date()
        )
    ]

    // MARK: Medications
    static let medications: [Medication] = [
        Medication(
            id:             "DEMO-MED-001",
            patientId:      "DEMO-PATIENT-001",
            medicationName: "Donepezil",
            medicationType: .tablet,
            dosage:         "10mg",
            notes:          "Take with water before bedtime",
            frequencyType:  .weekly,
            weekDays:       [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday],
            scheduledTimes: ["21:00"],
            isActive:       true,
            createdAt:      Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
            updatedAt:      Date()
        ),
        Medication(
            id:             "DEMO-MED-002",
            patientId:      "DEMO-PATIENT-001",
            medicationName: "Memantine",
            medicationType: .tablet,
            dosage:         "20mg",
            notes:          "Take with or without food",
            frequencyType:  .weekly,
            weekDays:       [.monday, .wednesday, .friday],
            scheduledTimes: ["08:00"],
            isActive:       true,
            createdAt:      Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
            updatedAt:      Date()
        ),
        Medication(
            id:             "DEMO-MED-003",
            patientId:      "DEMO-PATIENT-001",
            medicationName: "Vitamin D3",
            medicationType: .capsule,
            dosage:         "1000 IU",
            notes:          "Take with breakfast",
            frequencyType:  .weekly,
            weekDays:       [.monday, .thursday],
            scheduledTimes: ["09:00"],
            isActive:       true,
            createdAt:      Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
            updatedAt:      Date()
        )
    ]

    // MARK: Today's dose summary — matches TodayMedication(name:dosage:time:isTaken:icon:)
    static var todayMedications: [TodayMedication] {
        let today = Calendar.current.component(.weekday, from: Date())
        let weekdayMap: [Int: WeekDay] = [
            1: .sunday, 2: .monday, 3: .tuesday,
            4: .wednesday, 5: .thursday, 6: .friday, 7: .saturday
        ]
        let todayWeekday = weekdayMap[today]

        return medications.compactMap { med -> TodayMedication? in
            guard med.isActive else { return nil }
            switch med.frequencyType {
            case .weekly:
                guard let wd = todayWeekday, med.weekDays?.contains(wd) == true else { return nil }
            case .interval, .asNeeded:
                break
            }
            let time = med.scheduledTimes.first ?? "08:00"
            let icon = iconForType(med.medicationType)
            return TodayMedication(
                name: med.medicationName,
                dosage: "\(med.dosage) at \(time)",
                time: time,
                isTaken: false,
                icon: icon
            )
        }
    }

    private static func iconForType(_ type: MedicationType) -> Image {
        switch type {
        case .tablet:  return Image(systemName: "pills.fill")
        case .capsule: return Image(systemName: "capsule.fill")
        case .liquid:  return Image(systemName: "drop.fill")
        case .topical: return Image(systemName: "bandage.fill")
        case .other:   return Image(systemName: "cross.fill")
        }
    }
}
