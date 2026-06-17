//
//  RoleSelectionView.swift
//  awn app
//
//  Created by Joud Almashgari on 12/06/2026.
//

//
//  RoleSelectionView.swift
//  awn app
//

import SwiftUI

struct RoleSelectionView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var selectedRole: UserRole? = nil
    @State private var animateIn = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Background gradient (matches rest of app)
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 34)
                        .fill(Color(hex: "8B5CF6").opacity(0.20))
                        .frame(height: 330)
                        .offset(x: 0, y: -122)

                    Circle()
                        .fill(Color(hex: "6C7CD1").opacity(0.37))
                        .frame(width: 400, height: 460)
                        .offset(x: -300, y: -30)
                        .rotationEffect(.degrees(50))

                    Circle()
                        .fill(Color(hex: "8595E9").opacity(0.62))
                        .frame(width: 270, height: 400)
                        .offset(x: -366, y: -22)
                        .rotationEffect(.degrees(50))
                }
                Spacer()
            }

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Text("Welcome to Awn")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("How will you be using the app?")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 110)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)

                Spacer()

                // Role cards
                VStack(spacing: 16) {
                    RoleCard(
                        icon: "heart.fill",
                        title: "I'm a Caregiver",
                        subtitle: "I look after a family member with Alzheimer's and want to monitor their safety",
                        isSelected: selectedRole == .caregiver,
                        color: Color(hex: "6C7CD1")
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedRole = .caregiver
                        }
                    }

                    RoleCard(
                        icon: "person.fill",
                        title: "I'm a Patient",
                        subtitle: "My family uses Awn to help keep me safe, and I manage my own location sharing",
                        isSelected: selectedRole == .patient,
                        color: Color(hex: "8595E9")
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedRole = .patient
                        }
                    }
                }
                .padding(.horizontal, 24)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 30)

                Spacer()

                // Continue button
                Button(action: {
                    if let role = selectedRole {
                        authViewModel.setRole(role)
                    }
                }) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selectedRole != nil
                                      ? Color(hex: "6C7CD1")
                                      : Color.white.opacity(0.1))
                        )
                }
                .disabled(selectedRole == nil)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(animateIn ? 1 : 0)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animateIn = true
            }
        }
    }
}

// MARK: - Role Card

struct RoleCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(isSelected ? 0.3 : 0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(color)
                }

                // Text
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.55))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Checkmark
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? color : .white.opacity(0.2))
                    .padding(.top, 2)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? color.opacity(0.12) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isSelected ? color.opacity(0.5) : Color.white.opacity(0.08),
                                    lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RoleSelectionView()
        .environmentObject(AuthenticationViewModel())
}
