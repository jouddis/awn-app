//
//  CreateProfileSheet.swift
//  awn app
//
//  Created by Joud Almashgari on 12/06/2026.
//

//
//  CreateProfileSheet.swift
//  awn app
//
//  Shown to guest users from the Dashboard gear/profile button.
//  Prompts them to sign in with Apple to create a full profile.
//

import SwiftUI
import AuthenticationServices

struct CreateProfileSheet: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Background gradient
            VStack {
                ZStack {
                    Circle()
                        .fill(Color(hex: "6C7CD1").opacity(0.3))
                        .frame(width: 300, height: 300)
                        .offset(x: -120, y: -80)

                    Circle()
                        .fill(Color(hex: "8595E9").opacity(0.4))
                        .frame(width: 200, height: 200)
                        .offset(x: -160, y: -50)
                }
                Spacer()
            }

            VStack(spacing: 0) {
                // Drag handle
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 5)
                    .padding(.top, 14)

                Spacer()

                VStack(spacing: 20) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: "6C7CD1").opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 36))
                            .foregroundColor(Color(hex: "6C7CD1"))
                    }

                    VStack(spacing: 10) {
                        Text("Create Your Profile")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)

                        Text("Sign in with Apple to unlock the full Awn experience — monitor your family member, set safe zones, and receive real-time alerts.")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 10)
                    }

                    // Benefits list
                    VStack(alignment: .leading, spacing: 14) {
                        BenefitRow(icon: "location.fill",     color: Color(hex: "6C7CD1"), text: "Set and manage patient safe zones")
                        BenefitRow(icon: "bell.badge.fill",   color: .orange,               text: "Get notified when patient leaves safe zone")
                        BenefitRow(icon: "pills.fill",        color: .blue,                 text: "Track and manage medication schedules")
                        BenefitRow(icon: "applewatch",        color: .green,                text: "Connect patient's Apple Watch via Family Setup")
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                    )
                }
                .padding(.horizontal, 28)

                Spacer()

                // Sign in with Apple
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let auth):
                            authViewModel.handleSignInWithApple(authorization: auth)
                            dismiss()
                        case .failure(let error):
                            authViewModel.errorMessage = error.localizedDescription
                        }
                    }
                )
                .signInWithAppleButtonStyle(.white)
                .frame(height: 52)
                .cornerRadius(14)
                .padding(.horizontal, 28)

                Button("Maybe later") { dismiss() }
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.top, 12)
                    .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Benefit Row

struct BenefitRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 22)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
        }
    }
}

#Preview {
    CreateProfileSheet()
        .environmentObject(AuthenticationViewModel())
}
