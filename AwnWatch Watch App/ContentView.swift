//
//  ContentView.swift
//  AwnWatch Watch App
//
//  Created by Joud Almashgari on 11/12/2025.
//  Main navigation view for watchOS app
//  Simplified UI - Only shows monitoring status
//  Alerts are sent to caregiver's iPhone, not displayed on watch
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var viewModel = WatchViewModel()
    
    var body: some View {
        NavigationView {
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.currentPatient != nil {
                MonitoringView(viewModel: viewModel)
            } else {
                SetupRequiredView(viewModel: viewModel)
            }
        }
        .onAppear {
            // Changed from initialize() to fetchCurrentPatient()
            viewModel.fetchCurrentPatient()
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Setup Required View

struct SetupRequiredView: View {
    @ObservedObject var viewModel: WatchViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "iphone.and.arrow.forward")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Setup Required")
                .font(.headline)
            
            Text("Please complete setup on your caregiver's iPhone")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Add retry button
            Button("Retry") {
                viewModel.fetchCurrentPatient()
            }
            .buttonStyle(.bordered)
            .tint(.blue)
            .font(.caption)
        }
        .padding()
    }
}

// MARK: - Main Monitoring View

struct MonitoringView: View {
    @ObservedObject var viewModel: WatchViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Patient Info
                if let patient = viewModel.currentPatient {
                    PatientInfoCard(patient: patient)
                }
                
                // Monitoring Status
                MonitoringStatusCard(
                    isFallMonitoring: viewModel.isFallMonitoring,
                    isGeofenceMonitoring: viewModel.isGeofenceMonitoring,
                    isInsideSafeZone: viewModel.isInsideSafeZone,
                    monitoringMode: viewModel.monitoringMode
                )
                
                // Location Info
                if let location = viewModel.lastKnownLocation {
                    LocationCard(location: location)
                }
                
                // Refresh button
                Button(action: {
                    viewModel.refresh()
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .padding(.top, 8)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Component Views

struct PatientInfoCard: View {
    let patient: Patient
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text(patient.name)
                .font(.headline)
            
            if patient.hasSafeZone {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                    Text(patient.safeZoneDisplayName)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct MonitoringStatusCard: View {
    let isFallMonitoring: Bool
    let isGeofenceMonitoring: Bool
    let isInsideSafeZone: Bool
    let monitoringMode: GeofenceService.MonitoringMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Monitoring")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Fall Detection Status
            HStack(spacing: 4) {
                Circle()
                    .fill(isFallMonitoring ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text("Fall Detection")
                    .font(.caption)
            }
            
            // Geofence Status
            HStack(spacing: 4) {
                Circle()
                    .fill(isGeofenceMonitoring ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text("Safe Zone")
                    .font(.caption)
            }
            
            if isGeofenceMonitoring {
                Divider()
                    .padding(.vertical, 4)
                
                // Safe Zone Status
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: isInsideSafeZone ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(isInsideSafeZone ? .green : .orange)
                            .font(.caption)
                        Text(isInsideSafeZone ? "Inside Safe Zone" : "Outside Safe Zone")
                            .font(.caption)
                            .foregroundColor(isInsideSafeZone ? .green : .orange)
                    }
                    
                    // Monitoring Mode Indicator
                    HStack(spacing: 4) {
                        Image(systemName: monitoringMode == .lowPower ? "battery.100" : "bolt.fill")
                            .foregroundColor(monitoringMode == .lowPower ? .green : .orange)
                            .font(.caption2)
                        Text(monitoringMode.rawValue)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct LocationCard: View {
    let location: CLLocation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                Text("Current Location")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Lat: \(location.coordinate.latitude, specifier: "%.4f")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("Lon: \(location.coordinate.longitude, specifier: "%.4f")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Alert Type Extensions (Simplified - Only Your 3 Types)

extension AlertType {
    var icon: String {
        switch self {
        case .fallDetected:
            return "figure.fall"
        case .geofenceExit:
            return "location.circle"
        case .geofenceEntry:
            return "checkmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .fallDetected:
            return .red
        case .geofenceExit:
            return .orange
        case .geofenceEntry:
            return .green
        }
    }
}

#Preview {
    ContentView()
}
