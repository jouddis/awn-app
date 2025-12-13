//
//  DashboardView.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//
//  DashboardView.swift
//  awn app
//
//  Updated with pull-to-refresh and recent alerts
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    DashboardHeader(
                        caregiverName: authViewModel.currentUser?.fullName ?? "Caregiver",
                        patientName: viewModel.patientName,
                        lastUpdate: viewModel.lastUpdateTime
                    )
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Status Section
                            StatusSection(viewModel: viewModel)
                            
                            // Recent Alerts Section
                            if !viewModel.recentAlerts.isEmpty {
                                RecentAlertsSection(viewModel: viewModel)
                            }
                            
                            // Medications Section
                            MedicationsSection(viewModel: viewModel)
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                viewModel.loadDashboardData()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    // Refresh when app becomes active
                    if let patientID = viewModel.currentPatient?.id {
                        viewModel.fetchLatestAlerts(for: patientID)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Header

struct DashboardHeader: View {
    let caregiverName: String
    let patientName: String
    let lastUpdate: Date
    @State private var showDebugSettings = false
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Text("👤")
                        .font(.system(size: 24))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(caregiverName)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("Updated: \(lastUpdate, style: .relative) ago")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Spacer()
            
            Button(action: {
                showDebugSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
            }
            .padding(.trailing, 8)
            
            Button(action: {}) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.black)
        .sheet(isPresented: $showDebugSettings) {
            DebugSettingsView()
        }
    }
}

// MARK: - Status Section

struct StatusSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("How \(viewModel.patientName) is doing")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(viewModel.safeZoneStatus.displayText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(viewModel.safeZoneStatus.color)
            }
            
            HStack(spacing: 12) {
                StatusCard(
                    icon: "location.fill",
                    title: "Current place",
                    value: viewModel.currentLocation,
                    valueColor: viewModel.safeZoneStatus.color,
                    isAlert: viewModel.safeZoneStatus == .outside
                )
                
                StatusCard(
                    icon: "applewatch",
                    title: "Watch is",
                    value: viewModel.watchStatus.displayText,
                    valueColor: viewModel.watchStatus.color,
                    isAlert: viewModel.watchStatus == .disconnected
                )
            }
            
            HealthStatusCard(viewModel: viewModel)
        }
    }
}

// MARK: - Status Card

struct StatusCard: View {
    let icon: String
    let title: String
    let value: String
    let valueColor: Color
    let isAlert: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue.opacity(0.7))
                
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isAlert ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

// MARK: - Health Status Card

struct HealthStatusCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 24))
                .foregroundColor(.blue.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Health Status")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(viewModel.healthStatus.displayText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(viewModel.healthStatus.color)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(viewModel.healthStatus == .fallDetected ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

// MARK: - Recent Alerts Section (NEW)

struct RecentAlertsSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Alerts")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(viewModel.recentAlerts.count)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            ForEach(viewModel.recentAlerts.prefix(5)) { alert in
                AlertRow(alert: alert)
            }
        }
    }
}

struct AlertRow: View {
    let alert: AlertEvent
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: alertIcon)
                .font(.system(size: 20))
                .foregroundColor(alertColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alertTitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(alert.timestamp, style: .relative)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            if alert.isPendingConfirmation {
                Text("PENDING")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var alertIcon: String {
        switch alert.alertType {
        case .fallDetected:
            return "figure.fall"
        case .geofenceExit:
            return "location.circle"
        case .geofenceEntry:
            return "checkmark.circle"
        }
    }
    
    private var alertColor: Color {
        switch alert.alertType {
        case .fallDetected:
            return .red
        case .geofenceExit:
            return .orange
        case .geofenceEntry:
            return .green
        }
    }
    
    private var alertTitle: String {
        switch alert.alertType {
        case .fallDetected:
            return "Fall detected"
        case .geofenceExit:
            return "Left safe zone"
        case .geofenceEntry:
            return "Entered safe zone"
        }
    }
}

// MARK: - Medications Section

struct MedicationsSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Medications")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {}) {
                    Text("Show All")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
            }
            
            ForEach(viewModel.todayMedications) { medication in
                MedicationCard(medication: medication)
            }
        }
    }
}

// MARK: - Medication Card

struct MedicationCard: View {
    let medication: TodayMedication
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 60, height: 60)
                
                medication.icon
                    .font(.system(size: 32))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.blue.opacity(0.9))
                
                Text(medication.dosage)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            if medication.isTaken {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("Taken")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.2))
                .cornerRadius(20)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environmentObject(AuthenticationViewModel())
}
