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
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(ZStack { Capsule().fill(.black); Capsule().fill(Color(hex: "6C7CD1").opacity(0.19)) }
                .shadow(color: Color.white.opacity(0.1), radius: 5, x: 0, y: -2)
                .shadow(color: Color.black.opacity(10), radius: 0.2, x: 0.4, y: 0.5)
                .shadow(color: Color.white.opacity(5), radius: 0.2, x: -0.5, y: -0.5))
            .padding(.horizontal).padding(.bottom, -16)
        }
    }
}

struct MainTabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack{
            Button(action: action) {
                VStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                    
                    Text(title)
                        .font(.system(size: 12))
                }
                .foregroundColor(isSelected ? (Color(hex: "6C7CD1")) : .gray)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? .black : Color.clear).cornerRadius(44)
                
                
                
                
            }
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
