//
//  PatientSelfOnboardingView.swift
//  awn app
//
//  Created by Joud Almashgari on 12/06/2026.
//
//
//  PatientSelfOnboardingView.swift
//  awn app
//
//  Shown to users who signed in and chose role = Patient.
//  They enter their name, then land on a patient-specific dashboard
//  (location request management, not monitoring).
//

import SwiftUI

struct PatientSelfOnboardingView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var patientName: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @FocusState private var nameFocused: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Background gradient
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

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text("Almost there!")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("Tell us your name so your caregivers can identify you")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 110)

                    Color.clear.frame(height: 30)

                    // Name field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your Name")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "6C7CD1"))

                        TextField("Enter your name", text: $patientName)
                            .focused($nameFocused)
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.07))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.horizontal, 24)

                    // What this means
                    VStack(alignment: .leading, spacing: 14) {
                        Text("As a patient in Awn:")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.leading, 4)

                        InfoRow(icon: "location.slash.fill",
                                color: .orange,
                                text: "Your location is never shared without your explicit approval")

                        InfoRow(icon: "bell.badge.fill",
                                color: Color(hex: "6C7CD1"),
                                text: "You'll receive notifications when a caregiver requests location access")

                        InfoRow(icon: "hand.raised.fill",
                                color: .green,
                                text: "You can accept, decline, or revoke access at any time")
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 24)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                    }

                    Color.clear.frame(height: 100)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            // Bottom button
            VStack {
                Spacer()
                Button(action: completePatientSetup) {
                    HStack(spacing: 10) {
                        if isLoading {
                            ProgressView().tint(.white).scaleEffect(0.85)
                        }
                        Text(isLoading ? "Setting up..." : "Get Started")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(patientName.trimmingCharacters(in: .whitespaces).isEmpty
                                  ? Color.white.opacity(0.1)
                                  : Color(hex: "6C7CD1"))
                    )
                }
                .disabled(patientName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 44)
                .background(Color.black)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func completePatientSetup() {
        guard let user = authViewModel.currentUser else { return }
        let name = patientName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        nameFocused = false
        isLoading = true
        errorMessage = nil

        // Save a Patient record linked to this user's Apple ID
        // caregiverId is set to the user's own id (self-managed patient)
        let patient = Patient(
            name: name,
            caregiverId: user.id
        )

        CloudKitManager.shared.savePatient(patient) { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let saved):
                    print("✅ Patient self-profile created: \(saved.name)")
                    UserDefaults.standard.set(saved.id, forKey: Constants.UserDefaultsKeys.currentPatientID)
                    UserDefaults.standard.set(saved.name, forKey: "patientDisplayName")
                    authViewModel.completeOnboarding()
                case .failure(let error):
                    isLoading = false
                    errorMessage = "Could not save profile: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 22)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.75))
                .lineSpacing(3)
            Spacer()
        }
    }
}

#Preview {
    PatientSelfOnboardingView()
        .environmentObject(AuthenticationViewModel())
}
