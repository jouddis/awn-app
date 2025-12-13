//
//  AuthenticationView.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  Sign in with Apple - Caregiver only (no role selection)
//

import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
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
                    
                    Text("To stay updated with your patient’s safety and medications")
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
                
                
                // App logo/title
//                VStack(spacing: 12) {
//                    Text("Awn")
//                        .font(.system(size: 48, weight: .bold))
//                        .foregroundColor(.white)
//
//                    Text("Caring for those who matter most")
//                        .font(.system(size: 16))
//                        .foregroundColor(.white.opacity(0.7))
//                }
                
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
    }
}

// MARK: - Preview

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationViewModel())
}

