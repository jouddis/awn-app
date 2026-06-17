//
//  MonitoringReadinessService.swift
//  awn app
//
//  Created by Joud Almashgari on 13/06/2026.
//

//
//  MonitoringReadinessService.swift
//  awn app
//

import Foundation
import CoreLocation
import Combine

class MonitoringReadinessService: ObservableObject {
    static let shared = MonitoringReadinessService()
    private init() {}

    @Published var readiness: MonitoringReadiness = .empty

    func evaluate(patient: Patient?, locationRequestStatus: LocationRequestStatus?) {
        let patientLinked           = patient != nil
        let locationSharingAccepted = locationRequestStatus == .accepted
        let watchPaired             = patient?.isWatchPaired ?? false
        let locationPermission      = checkLocationPermission()
        let firstLocationReceived   = patient?.lastLocationTimestamp != nil

        readiness = MonitoringReadiness(
            patientLinked:           patientLinked,
            locationSharingAccepted: locationSharingAccepted,
            watchPaired:             watchPaired,
            locationPermission:      locationPermission,
            firstLocationReceived:   firstLocationReceived
        )
    }

    func evaluateForDemo() {
        readiness = .fullDemo
    }

    private func checkLocationPermission() -> Bool {
        let status = CLLocationManager().authorizationStatus
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }
}
