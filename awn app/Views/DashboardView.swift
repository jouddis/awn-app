//
//  DashboardView.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationStack {  // ✅ Wrap entire dashboard in NavigationStack
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    DashboardHeader(
                        caregiverName: authViewModel.currentUser?.fullName ?? "Caregiver",
                        patientName: viewModel.patientName
                    )
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Status Section
                            StatusSection(viewModel: viewModel)
                            
                            // Medications Section
                            MedicationsSection(viewModel: viewModel)
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                  
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                viewModel.loadDashboardData()
            }
            .navigationBarHidden(true)  // Hide default nav bar
        }
    }
}

// MARK: - Header

struct DashboardHeader: View {
    let caregiverName: String
    let patientName: String
    @State private var showDebugSettings = false
    
    var body: some View {
        HStack {
            // Profile image placeholder
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
            }
            
            Spacer()
            
            // Debug settings (temporary)
            Button(action: {
                showDebugSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
            }
            .padding(.trailing, 8)
            
            // Notification bell
            Button(action: {
                // Show notifications
            }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    // Notification badge
                    if true { // Has unread
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
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

// MARK: - Status Section

struct StatusSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section title with status indicator
            HStack {
                Text("How \(viewModel.patientName) is doing")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Status text
                Text(viewModel.safeZoneStatus.displayText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(viewModel.safeZoneStatus.color)
            }
            
            // Status cards row 1
            HStack(spacing: 12) {
                // Location card
                StatusCard(
                    icon: "location.fill",
                    title: "Current place",
                    value: viewModel.currentLocation,
                    valueColor: viewModel.safeZoneStatus.color,
                    isAlert: viewModel.safeZoneStatus == .outside
                )
                
                // Watch connection card
                StatusCard(
                    icon: "applewatch",
                    title: "Watch is",
                    value: viewModel.watchStatus.displayText,
                    valueColor: viewModel.watchStatus.color,
                    isAlert: viewModel.watchStatus == .disconnected
                )
            }
            
            // Health status card
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

// MARK: - Medications Section

struct MedicationsSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("Medications")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    // Show all medications
                }) {
                    Text("Show All")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
            }
            
            // Medication cards
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
            // Medication icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 60, height: 60)
                
                // Pill illustration (simplified)
                medication.icon
                    .font(.system(size: 32))
            }
            
            // Medication info
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.blue.opacity(0.9))
                
                Text(medication.dosage)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Taken indicator
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

// MARK: - Bottom Tab Bar (with NavigationLinks)

struct BottomTabBar: View {
    @State private var selectedTab: Tab = .home
    
    enum Tab {
        case home, location, medications
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Home
                TabBarButton(
                    icon: "house.fill",
                    title: "Home",
                    isSelected: selectedTab == .home
                ) {
                    selectedTab = .home
                }
                
                // Location - NavigationLink instead of sheet ✅
                NavigationLink(destination: SafeZoneView()) {
                    VStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 22))
                        
                        Text("Location")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(selectedTab == .location ? .blue : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    selectedTab = .location
                })
                
                // Medications - NavigationLink (placeholder) ✅
                NavigationLink(destination: MedicationsPlaceholderView()) {
                    VStack(spacing: 6) {
                        Image(systemName: "pills.fill")
                            .font(.system(size: 22))
                        
                        Text("Medicines")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(selectedTab == .medications ? .blue : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    selectedTab = .medications
                })
            }
            .padding(.vertical, 12)
            .background(
                Color.gray.opacity(0.1)
                    .blur(radius: 20)
            )
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                
                Text(title)
                    .font(.system(size: 12))
            }
            .foregroundColor(isSelected ? .blue : .white.opacity(0.5))
            .frame(maxWidth: .infinity)
        }
    }
}


// MARK: - Preview

#Preview {
    DashboardView()
        .environmentObject(AuthenticationViewModel())
}

