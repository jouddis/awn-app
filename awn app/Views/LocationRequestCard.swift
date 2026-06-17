//
//  LocationRequestCard.swift
//  awn app
//
//  Created by Joud Almashgari on 12/06/2026.
//

//
//  LocationRequestCard.swift
//  awn app
//
//  Add this card inside DashboardView's StatusSection.
//  Shows location access status and lets caregiver send a request.
//
//  HOW TO ADD TO DashboardView.swift:
//  Inside StatusSection, add at the top:
//      LocationRequestCard(viewModel: locationRequestVM)
//
//  And in DashboardView, add:
//      @StateObject private var locationRequestVM = LocationRequestViewModel()
//  Then after .onAppear { viewModel.loadDashboardData() } pass the patient:
//      .onChange(of: viewModel.currentPatient) { patient in
//          if let p = patient { locationRequestVM.setup(patient: p, caregiver: authViewModel.currentUser) }
//      }

import SwiftUI
import CoreLocation
import Combine

// MARK: - Location Request Card

struct LocationRequestCard: View {
    @ObservedObject var viewModel: LocationRequestViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch viewModel.requestStatus {
            case .none:
                NoRequestView(isLoading: viewModel.isLoading, onRequest: viewModel.sendRequest)

            case .pending:
                PendingRequestView(onResend: viewModel.resendRequest)

            case .accepted:
                LocationAcceptedView(
                    isInsideSafeZone: viewModel.isInsideSafeZone,
                    locationSource: viewModel.locationSource
                )

            case .declined:
                DeclinedRequestView(onResend: viewModel.resendRequest)

            case .revoked:
                RevokedView(onResend: viewModel.resendRequest)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.07))
        .cornerRadius(16)
        .onAppear { viewModel.checkStatus() }
    }
}

// MARK: - Sub Views

private struct NoRequestView: View {
    let isLoading: Bool
    let onRequest: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 28))
                .foregroundColor(.gray)

            VStack(alignment: .leading, spacing: 4) {
                Text("Location not shared")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text("Request access to see safe zone status")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Button(action: onRequest) {
                if isLoading {
                    ProgressView().tint(.white).scaleEffect(0.8)
                } else {
                    Text("Request")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(hex: "6C7CD1"))
                        .cornerRadius(10)
                }
            }
            .disabled(isLoading)
        }
    }
}

private struct PendingRequestView: View {
    let onResend: () -> Void
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .scaleEffect(pulse ? 1.2 : 1.0)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            pulse = true
                        }
                    }
                Image(systemName: "clock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Waiting for patient...")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text("Request sent, awaiting approval")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Button("Resend") { onResend() }
                .font(.system(size: 12))
                .foregroundColor(.orange)
        }
    }
}

struct LocationAcceptedView: View {
    let isInsideSafeZone: Bool?
    let locationSource: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 13))
                Text("Location access granted")
                    .font(.caption)
                    .foregroundColor(.green)
                Spacer()
                Text(locationSource)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Divider().background(Color.white.opacity(0.1))

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill((isInsideSafeZone == true ? Color.green : Color.red).opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: isInsideSafeZone == true
                          ? "checkmark.shield.fill"
                          : "exclamationmark.triangle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(isInsideSafeZone == true ? .green : .red)
                }

                VStack(alignment: .leading, spacing: 4) {
                    if let inside = isInsideSafeZone {
                        Text(inside ? "Inside safe zone" : "Outside safe zone!")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(inside ? .green : .red)
                        Text(inside
                             ? "Patient is in a safe area"
                             : "Patient has left the safe area")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text("Checking location...")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
            }
        }
    }
}

private struct DeclinedRequestView: View {
    let onResend: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 28))
                .foregroundColor(.red.opacity(0.7))

            VStack(alignment: .leading, spacing: 4) {
                Text("Request declined")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text("Patient chose not to share location")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Button("Try again") { onResend() }
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .underline()
        }
    }
}

private struct RevokedView: View {
    let onResend: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 28))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Location access removed")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text("Patient stopped sharing their location")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Button(action: onResend) {
                Text("Request")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(hex: "6C7CD1"))
                    .cornerRadius(10)
            }
        }
    }
}

// MARK: - ViewModel

class LocationRequestViewModel: ObservableObject {
    @Published var requestStatus: LocationRequestStatus? = nil
    @Published var isInsideSafeZone: Bool? = nil
    @Published var locationSource: String = "From iPhone 📱"
    @Published var isLoading = false

    private let cloudKitManager = CloudKitManager.shared
    private var caregiverId: String = ""
    private var caregiverName: String = ""
    private var patientId: String = ""
    private var patient: Patient?

    // Call this after patient data is loaded in DashboardViewModel
    func setup(patient: Patient, caregiver: AppUser?) {
        self.patient = patient
        self.patientId = patient.id
        self.caregiverId = caregiver?.id ?? ""
        self.caregiverName = caregiver?.fullName ?? "Caregiver"
        checkStatus()
    }

    func checkStatus() {
        guard !caregiverId.isEmpty, !patientId.isEmpty else { return }

        cloudKitManager.fetchLocationRequestStatus(
            caregiverId: caregiverId,
            patientId: patientId
        ) { [weak self] result in
            switch result {
            case .success(let request):
                self?.requestStatus = request?.status
                if request?.status == .accepted {
                    self?.updateSafeZoneStatus()
                }
            case .failure:
                self?.requestStatus = nil
            }
        }
    }

    func sendRequest() {
        guard !caregiverId.isEmpty, !patientId.isEmpty else { return }

        isLoading = true
        let request = LocationSharingRequest(
            caregiverId: caregiverId,
            caregiverName: caregiverName,
            patientId: patientId
        )

        cloudKitManager.saveLocationRequest(request) { [weak self] result in
            self?.isLoading = false
            switch result {
            case .success:
                self?.requestStatus = .pending
            case .failure(let error):
                print("❌ Failed to send location request: \(error)")
            }
        }
    }

    func resendRequest() {
        requestStatus = nil
        sendRequest()
    }

    private func updateSafeZoneStatus() {
        guard let patient = patient,
              let lat = patient.safeZoneCenterLat,
              let lon = patient.safeZoneCenterLon,
              let radius = patient.safeZoneRadius else {
            isInsideSafeZone = nil
            return
        }

        // Use watch location if iPhone location is stale
        // For now this is set by WatchViewModel via NotificationCenter
        let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        locationSource = "From Apple Watch ⌚" // Will be updated by location service
        _ = center
        _ = radius
        // TODO: Wire to actual LocationService when available
    }
}
