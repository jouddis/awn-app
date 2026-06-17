//
//  MonitoringReadiness.swift
//  awn app
//
//  Created by Joud Almashgari on 13/06/2026.
//

//
//  MonitoringReadiness.swift
//  awn app
//

import Foundation
import SwiftUI

// MARK: - Model

struct MonitoringReadiness {
    var patientLinked:          Bool
    var locationSharingAccepted: Bool
    var watchPaired:            Bool
    var locationPermission:     Bool
    var firstLocationReceived:  Bool

    var score: Int {
        [patientLinked, locationSharingAccepted, watchPaired,
         locationPermission, firstLocationReceived].filter { $0 }.count
    }

    var percentage: Int { score * 20 }  // 5 items × 20 = 100

    var level: ReadinessLevel {
        switch percentage {
        case 80...100: return .active
        case 40..<80:  return .partial
        default:       return .inactive
        }
    }

    var items: [ReadinessItem] {[
        ReadinessItem(label: "Patient Linked",
                      actionLabel: "Add Patient",
                      done: patientLinked),
        ReadinessItem(label: "Location Sharing Accepted",
                      actionLabel: "Send Request",
                      done: locationSharingAccepted),
        ReadinessItem(label: "Watch Paired",
                      actionLabel: "Pair Watch",
                      done: watchPaired),
        ReadinessItem(label: "Location Permission Granted",
                      actionLabel: "Grant Permission",
                      done: locationPermission),
        ReadinessItem(label: "First Location Received",
                      actionLabel: "Waiting…",
                      done: firstLocationReceived),
    ]}

    static var empty: MonitoringReadiness {
        MonitoringReadiness(
            patientLinked:           false,
            locationSharingAccepted: false,
            watchPaired:             false,
            locationPermission:      false,
            firstLocationReceived:   false
        )
    }

    static var fullDemo: MonitoringReadiness {
        MonitoringReadiness(
            patientLinked:           true,
            locationSharingAccepted: true,
            watchPaired:             true,
            locationPermission:      true,
            firstLocationReceived:   true
        )
    }
}

// MARK: - Readiness Level

enum ReadinessLevel {
    case inactive, partial, active

    var color: Color {
        switch self {
        case .inactive: return .red
        case .partial:  return .orange
        case .active:   return .green
        }
    }

    var label: String {
        switch self {
        case .inactive: return "Not Active"
        case .partial:  return "Partially Active"
        case .active:   return "Active"
        }
    }

    var icon: String {
        switch self {
        case .inactive: return "exclamationmark.circle.fill"
        case .partial:  return "exclamationmark.triangle.fill"
        case .active:   return "checkmark.circle.fill"
        }
    }
}

// MARK: - Readiness Item

struct ReadinessItem: Identifiable {
    let id = UUID()
    let label: String
    let actionLabel: String
    let done: Bool
}
