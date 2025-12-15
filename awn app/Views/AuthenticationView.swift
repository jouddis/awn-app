//
//  AuthenticationView.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  Sign in with Apple - Caregiver only (no role selection)
//  Updated with hidden demo mode for Apple Review
//

import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    // Demo mode state
    @State private var showDemoMode = false
    @State private var tapCount = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                ZStack{
                    RoundedRectangle(cornerRadius: 34)
                        .fill(Color(hex: "8B5CF6").opacity(0.20))
                    
                    
                        .frame(height: 330)
                        .offset(x: 0, y: -122)


                        .shadow(color: Color.black.opacity(22), radius: 0.1, x: 0, y: -0.4)
                        .shadow(color: Color.white.opacity(22), radius: 0.12, x: -0.5, y: -0.12)
                    
                    // هذا عشان يصير فيه شوي قلاس ايفكت
                        .overlay(
                            RoundedRectangle(cornerRadius: 35)
                                .stroke(Color.white.opacity(0.05), lineWidth: 4)
                                .shadow(color: Color.white.opacity(0.12), radius: 2, x: 22, y: 33)
                                .shadow(color: Color.white.opacity(12), radius: 0.6, x: 0.5, y: 0)
                              .offset(x: 0, y: -122)
     
                        )
                    // الدائره البنفسجيه الاولى
                    Circle()
                        .fill(Color(hex: "6C7CD1").opacity(0.37))
                        .frame(width: 400, height: 460)
                        .offset(x: -300, y: -30)
                        .rotationEffect(.degrees(50))
                    // الدائره البنفسجيه الثانيه
                    Circle()
                        .fill(Color(hex: "8595E9").opacity(0.62))
                        .frame(width: 270, height: 400)
                        .offset(x: -366, y: -22)
                        .rotationEffect(.degrees(50))
                }
                
                    Spacer()
                }
            VStack(spacing: 20) {
                VStack(spacing: 15) {
                    Text("Sign in to your\nAccount")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("To stay updated with your patient's safety and medications")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                       // .padding(.horizontal, 40)
                        .frame(width: 280)
                }
                .padding(.top, 78)
                
                Spacer()
                
            }
            
            VStack(spacing: 20) {
                Spacer()
                
                

                
                Spacer()
                Text("Please sign in with Apple")
                    .foregroundColor(.gray)
                    .font(.system(size: 18, weight: .regular))
                
                // Sign in with Apple button
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            // Sign in as caregiver (role handled internally)
                            authViewModel.handleSignInWithApple(authorization: authorization)
                            
                        case .failure(let error):
                            authViewModel.errorMessage = error.localizedDescription
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(12)
                .glassEffect()
                .padding(.horizontal, 32)
                .shadow(color: Color.black.opacity(22), radius: 0.1, x: 0.7, y: 0.5)
                .shadow(color: Color.white.opacity(22), radius: 0.6, x: -0.5, y: -0.5)
                
                // 🔐 HIDDEN DEMO MODE TRIGGER
                // Tap this area 5 times quickly to reveal demo login
                Color.clear
                    .frame(height: 60)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        tapCount += 1
                        print("Tap count: \(tapCount)")
                        
                        if tapCount >= 5 {
                            showDemoMode = true
                            tapCount = 0
                            print("🎭 Opening demo mode...")
                        }
                        
                        // Reset counter after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            if self.tapCount > 0 && self.tapCount < 5 {
                                self.tapCount = 0
                            }
                        }
                    }
                
                // Error message
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal, 32)
                }
                
                // Loading indicator
                if authViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                }
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showDemoMode) {
            DemoModeLoginView()
                .environmentObject(authViewModel)
        }
    }
}

// MARK: - Demo Mode Login View (For Apple Review ONLY)

struct DemoModeLoginView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var username = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: "6C7CD1"))
                        
                        Text("Demo Mode")
                            .font(.title)
                            .foregroundColor(.white)
                        
                        Text("For Apple Review Only")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // Login Form
                    VStack(spacing: 16) {
                        // Username Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            TextField("", text: $username)
                                .textFieldStyle(.plain)
                                .padding(16)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            SecureField("", text: $password)
                                .textFieldStyle(.plain)
                                .padding(16)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }
                        
                        // Error Message
                        if showError {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 8)
                        }
                        
                        // Sign In Button
                        Button(action: signInDemo) {
                            Text("Sign In")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(hex: "6C7CD1"))
                                .cornerRadius(12)
                        }
                        .padding(.top, 16)
                        
                        // Help Text
                        VStack(spacing: 4) {
                            Text("Demo Credentials:")
                                .font(.caption2)
                                .foregroundColor(.gray.opacity(0.7))
                            
                            Text("demo@awnapp.com")
                                .font(.caption2)
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("DemoPass123!")
                                .font(.caption2)
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "6C7CD1"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func signInDemo() {
        // Validate credentials
        if username == "demo@awnapp.com" && password == "DemoPass123!" {
            print("✅ Demo credentials valid, logging in...")
            authViewModel.loginAsDemoUser()
            dismiss()
        } else {
            errorMessage = "Invalid credentials. Use:\ndemo@awnapp.com\nDemoPass123!"
            showError = true
            
            // Hide error after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showError = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationViewModel())
}
