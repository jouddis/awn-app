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
//  Updated with beautiful HomeView UI design
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.scenePhase) var scenePhase
    @State private var showNotificationsPanel = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    DashboardHeader(
                        caregiverName: authViewModel.currentUser?.fullName ?? "Caregiver",
                        patientName: viewModel.patientName,
                        lastUpdate: viewModel.lastUpdateTime,
                        hasUnreadAlerts: viewModel.hasUnreadAlerts,
                        onNotificationTap: {
                            showNotificationsPanel = true
                            viewModel.markAlertsAsRead()
                        }
                    )
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            
                            // DYNAMIC CONTENT BASED ON STATE
                            if !viewModel.hasLocation && !viewModel.hasMedication {
                                // 1. EMPTY STATE - No location, no medication
                                EmptyStateView()
                                
                            } else {
                                // 2. LOCATION ADDED - Show status cards
                                if viewModel.hasLocation {
                                    StatusSection(viewModel: viewModel)
                                }
                                
                                // 3. MEDICATION ADDED - Show medicine cards (only today's meds)
                                if viewModel.hasMedication && !viewModel.todayMedications.isEmpty {
                                    MedicationsSection(viewModel: viewModel)
                                }
                            }
                            
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
                    if let patientID = viewModel.currentPatient?.id {
                        viewModel.fetchLatestAlerts(for: patientID)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showNotificationsPanel) {
                NotificationsPanel(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Add Patient Location Card
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: "6C7CD1"))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add Patient Location")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("To enable tracking, please add the location.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                NavigationLink(destination: SafeZoneView()) {
                    Text("Add Location")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "6C7CD1"))
                        .cornerRadius(12)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
            )
            
            // Add Patient Medicines Card
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "pill.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: "6C7CD1"))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add Patient Medicines")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Add medicines to enable notifications.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                NavigationLink(destination: MedicationsPlaceholderView()) {
                    Text("Add Medicines")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "6C7CD1"))
                        .cornerRadius(12)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
            )
            
            Spacer()
        }
    }
}

// MARK: - Header

struct DashboardHeader: View {
    let caregiverName: String
    let patientName: String
    let lastUpdate: Date
    let hasUnreadAlerts: Bool
    let onNotificationTap: () -> Void
    @State private var showDebugSettings = false
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.black)
                .frame(width: 50, height: 50)
                .overlay(Image(systemName: "person.fill").resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(Color(hex: "6C7CD1")),
                )
                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                .shadow(color: Color.white.opacity(0.1), radius: 5)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Welcome back")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Updated: \(lastUpdate, style: .relative) ago")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.leading, 5)
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
            
            // Notification Bell with Red Dot Indicator
            Button(action: onNotificationTap) {
                ZStack(alignment: .topTrailing) {
                    Circle().fill(Color.black).frame(width: 45, height: 45)
                        .overlay(Image(systemName: "bell.fill").foregroundColor(Color(hex: "6C7CD1")))
                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .shadow(color: Color.white.opacity(0.1), radius: 5)
                    
                    // Red dot - only show if there are unread alerts
                    if hasUnreadAlerts {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                            .offset(x: 2, y: -2)
                    }
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

// MARK: - Notifications Panel

struct NotificationsPanel: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if viewModel.recentAlerts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Alerts")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("All clear! No recent alerts.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.recentAlerts) { alert in
                                AlertRow(alert: alert)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "6C7CD1"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Status Section (Beautiful HomeView Design)

struct StatusSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            // Watch Status Card (Beautiful Design from HomeView)
            WatchStatusCard(viewModel: viewModel)
            
            // Fall Detection Card
            FallDetectionStatusCard(viewModel: viewModel)
        }
    }
}

// MARK: - Watch Status Card (Beautiful Design)

struct WatchStatusCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    // Computed properties based on safe zone status
    var isHome: Bool {
        viewModel.safeZoneStatus == .inside
    }
    
    var statusColor: Color {
        isHome ? .green : .orange
    }
    
    var locationText: String {
        switch viewModel.safeZoneStatus {
        case .inside:
            return "Home"
        case .outside:
            return "Outside"
        case .unknown:
            return "Unknown"
        }
    }
    
    var badgeIcon: String {
        isHome ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
    }
    
    var statusLabel: String {
        isHome ? "Safe Zone" : "Roaming"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Watch Status")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(alignment: .center, spacing: 15) {
                
                // 1. Watch Icon with Badge
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "6C7CD1").opacity(0.2))
                            .frame(width: 50, height: 50)
                        Image(systemName: "applewatch.side.right")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "6C7CD1"))
                    }
                    // Badge (checkmark or warning)
                    Image(systemName: badgeIcon)
                        .font(.system(size: 16))
                        .foregroundColor(statusColor)
                        .background(Color.black.clipShape(Circle()))
                        .offset(x: 5, y: 5)
                }
                
                // 2. Location Text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current place")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(locationText)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(isHome ? .white : .orange)
                }
                
                Spacer()
                
                // 3. Battery & Status Badge
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "battery.100")
                            .foregroundColor(.white)
                        Text("87%")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    Text(statusLabel)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "1C1C1E"))
        )
    }
}

// MARK: - Fall Detection Status Card

struct FallDetectionStatusCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var fallDetected: Bool {
        viewModel.healthStatus == .fallDetected
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Fall Detection")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 15) {
                Image(systemName: fallDetected ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(fallDetected ? .red : Color(hex: "8595E9"))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(fallDetected ? "Detected" : "No Falls")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
//                    Text("in the last 24 hours")
//                        .font(.subheadline)
//                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Enabled")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "1C1C1E"))
        )
    }
}

// MARK: - Alert Row

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
                
                NavigationLink(destination: MedicationsPlaceholderView()) {
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
