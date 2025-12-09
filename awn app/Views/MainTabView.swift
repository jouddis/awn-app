//
//  Untitled.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  Main tab container - switches between Home/Location/Medications
//

import SwiftUI
import Combine

struct MainTabView: View {
    @StateObject private var tabManager = TabManager()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Show different content based on selected tab
                    Group {
                        switch tabManager.selectedTab {
                        case .home:
                            DashboardView()
                                .environmentObject(authViewModel)
                            
                        case .location:
                            SafeZoneView()
                            
                        case .medications:
                            MedicationsPlaceholderView()
                        }
                    }
                    
                    Spacer()
                    
                    // Bottom Tab Bar (always visible)
                    MainBottomTabBar(tabManager: tabManager)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Tab Manager

class TabManager: ObservableObject {
    @Published var selectedTab: Tab = .home
    
    enum Tab {
        case home
        case location
        case medications
    }
}

// MARK: - Main Bottom Tab Bar

struct MainBottomTabBar: View {
    @ObservedObject var tabManager: TabManager
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Home Tab
                MainTabButton(
                    icon: "house.fill",
                    title: "Home",
                    isSelected: tabManager.selectedTab == .home
                ) {
                    tabManager.selectedTab = .home
                }
                
                // Location Tab
                MainTabButton(
                    icon: "location.fill",
                    title: "Location",
                    isSelected: tabManager.selectedTab == .location
                ) {
                    tabManager.selectedTab = .location
                }
                
                // Medications Tab
                MainTabButton(
                    icon: "pills.fill",
                    title: "Medicines",
                    isSelected: tabManager.selectedTab == .medications
                ) {
                    tabManager.selectedTab = .medications
                }
            }
            .padding(.vertical, 12)
            .background(
                Color.gray.opacity(0.1)
                    .blur(radius: 20)
            )
        }
    }
}

struct MainTabButton: View {
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

// MARK: - Medications Placeholder

struct MedicationsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "pills.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Medications")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Coming Soon")
                .font(.system(size: 18))
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environmentObject(AuthenticationViewModel())
}
