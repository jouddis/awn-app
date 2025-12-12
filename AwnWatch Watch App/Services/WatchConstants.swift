//
//  Watch.swift
//  awn app
//
//  Created by Joud Almashgari on 11/12/2025.
//
//

import Foundation
import CoreLocation

// MARK: - Watch App Constants

extension Constants {
    
    enum Watch {
        // Location update intervals
        static let locationUpdateInterval: TimeInterval = 30.0
        
        // Alert limits
        static let maxRecentAlerts = 10
        
        // Patient data cache keys
        static let currentPatientIDKey = "currentPatientID"
        
        // UI refresh intervals
        static let statusRefreshInterval: TimeInterval = 60.0
    }
    
    // Notification names for watch-specific events
    enum WatchNotifications {
        static let patientConfigured = Notification.Name("WatchPatientConfigured")
        static let monitoringStarted = Notification.Name("WatchMonitoringStarted")
        static let monitoringStopped = Notification.Name("WatchMonitoringStopped")
    }
}

// MARK: - Location Extensions

extension CLLocation {
    /// Format coordinate for display
    func formattedCoordinate() -> String {
        return String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
    }
    
    /// Check if location is valid
    var isValid: Bool {
        return coordinate.latitude != 0 && coordinate.longitude != 0
    }
}

// MARK: - Date Extensions

extension Date {
    /// Format for watch display
    func watchDisplayFormat() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - Watch Complication Data

struct WatchComplicationData {
    let isMonitoring: Bool
    let isInsideSafeZone: Bool
    let alertCount: Int
    let lastUpdate: Date
    
    var statusText: String {
        if !isMonitoring {
            return "Not Monitoring"
        } else if !isInsideSafeZone {
            return "Outside Safe Zone"
        } else if alertCount > 0 {
            return "\(alertCount) Alert\(alertCount == 1 ? "" : "s")"
        } else {
            return "All Good"
        }
    }
    
    var statusEmoji: String {
        if !isMonitoring {
            return "⏸️"
        } else if !isInsideSafeZone {
            return "⚠️"
        } else if alertCount > 0 {
            return "🔔"
        } else {
            return "✅"
        }
    }
}
