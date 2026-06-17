//
//  PatientLocationRequestView.swift
//  awn app
//
//  Created by Joud Almashgari on 12/06/2026.
//
//  Shown to the patient when a caregiver requests location access.
//  Add a button in MainTabView or PatientOnboardingView to surface this.
//
//
//  PatientLocationRequestView.swift
//  awn app
//
//  Created by Joud Almashgari on 12/06/2026.
//

//
//  PatientLocationRequestView.swift
//  awn app
//
//  Shown to the patient when a caregiver requests location access.
//  Add a button in MainTabView or PatientOnboardingView to surface this.
//

import SwiftUI
import Combine

// MARK: - Patient Location Requests View

struct PatientLocationRequestsView: View {
    @StateObject private var viewModel: PatientLocationRequestsViewModel
    @Environment(\.dismiss) var dismiss

    init(patientId: String) {
        _viewModel = StateObject(
            wrappedValue: PatientLocationRequestsViewModel(patientId: patientId)
        )
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView().tint(.white)

                } else if viewModel.pendingRequests.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)

                        Text("No pending requests")
                            .font(.title3)
                            .foregroundColor(.white)

                        Text("You have no location sharing requests right now")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(viewModel.pendingRequests) { request in
                                LocationRequestRow(
                                    request: request,
                                    onAccept: { viewModel.accept(request) },
                                    onDecline: { viewModel.decline(request) }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Location Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "6C7CD1"))
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { viewModel.fetchRequests() }
    }
}

// MARK: - Request Row

struct LocationRequestRow: View {
    let request: LocationSharingRequest
    let onAccept: () -> Void
    let onDecline: () -> Void
    @State private var isResponding = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: "6C7CD1").opacity(0.3))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(Color(hex: "6C7CD1"))
                            .font(.system(size: 22))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(request.caregiverName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text(request.requestedAt.timeAgoString())
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Text("Pending")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }

            // Description
            Text("\(request.caregiverName) is requesting access to your location to make sure you're safe.")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .lineSpacing(4)

            // What they'll see
            VStack(alignment: .leading, spacing: 8) {
                Text("They will be able to see:")
                    .font(.caption)
                    .foregroundColor(.gray)

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green).font(.caption)
                    Text("Whether you're inside your safe zone")
                        .font(.caption).foregroundColor(.white.opacity(0.8))
                }

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green).font(.caption)
                    Text("Your real-time location from iPhone or Apple Watch")
                        .font(.caption).foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)

            // Buttons
            HStack(spacing: 12) {
                Button(action: {
                    isResponding = true
                    onDecline()
                }) {
                    Text("Decline")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                }
                .disabled(isResponding)

                Button(action: {
                    isResponding = true
                    onAccept()
                }) {
                    HStack(spacing: 6) {
                        if isResponding {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        }
                        Text("Share Location")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color(hex: "6C7CD1"))
                    .cornerRadius(12)
                }
                .disabled(isResponding)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.07))
        .cornerRadius(16)
    }
}

// MARK: - ViewModel

class PatientLocationRequestsViewModel: ObservableObject {
    @Published var pendingRequests: [LocationSharingRequest] = []
    @Published var isLoading = false

    private let cloudKitManager = CloudKitManager.shared
    private let patientId: String

    init(patientId: String) {
        self.patientId = patientId
    }

    func fetchRequests() {
        // Don't hit CloudKit for demo IDs or unauthenticated sessions
        guard !patientId.hasPrefix("DEMO-"),
              !patientId.isEmpty,
              !DemoSession.shared.isActive else {
            isLoading = false
            return
        }
        isLoading = true
        cloudKitManager.fetchPendingRequestsForPatient(patientId: patientId) { [weak self] result in
            self?.isLoading = false
            switch result {
            case .success(let requests):
                self?.pendingRequests = requests
            case .failure(let error):
                print("❌ Failed to fetch requests: \(error)")
            }
        }
    }

    func accept(_ request: LocationSharingRequest) {
        cloudKitManager.updateLocationRequestStatus(requestId: request.id, newStatus: .accepted) { [weak self] result in
            if case .success = result {
                self?.pendingRequests.removeAll { $0.id == request.id }
                print("✅ Location request accepted")
            }
        }
    }

    func decline(_ request: LocationSharingRequest) {
        cloudKitManager.updateLocationRequestStatus(requestId: request.id, newStatus: .declined) { [weak self] result in
            if case .success = result {
                self?.pendingRequests.removeAll { $0.id == request.id }
                print("✅ Location request declined")
            }
        }
    }
}

// MARK: - Date Extension

extension Date {
    func timeAgoString() -> String {
        let seconds = Int(-timeIntervalSinceNow)
        if seconds < 60 { return "Just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }
}
