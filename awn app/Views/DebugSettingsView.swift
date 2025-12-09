//
//  DebugSettingsView.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  Debug view to test login flow
//

import SwiftUI

struct DebugSettingsView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Debug Actions") {
                    Button(action: {
                        authViewModel.signOut()
                    }) {
                        HStack {
                            Image(systemName: "arrow.backward.circle.fill")
                                .foregroundColor(.red)
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Button(action: {
                        clearAllData()
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.orange)
                            Text("Clear All Local Data")
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Section("Current User") {
                    if let user = authViewModel.currentUser {
                        LabeledContent("Name", value: user.fullName ?? "Unknown")
                        LabeledContent("Email", value: user.email ?? "No email")
                        LabeledContent("Role", value: user.role)
                        LabeledContent("User ID", value: user.id)
                    } else {
                        Text("Not signed in")
                            .foregroundColor(.gray)
                    }
                }
                
                Section("Info") {
                    Text("Use these debug actions to test the complete flow from scratch")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Debug Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func clearAllData() {
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.appleUserID)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.currentUserID)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.userRole)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.isAuthenticated)
        
        // Sign out
        authViewModel.signOut()
        
        print("✅ All local data cleared")
    }
}

#Preview {
    DebugSettingsView()
        .environmentObject(AuthenticationViewModel())
}

