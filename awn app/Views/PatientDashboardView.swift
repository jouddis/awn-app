//
//  PatientDashboardView.swift
//  awn app
//
//  Created by Joud Almashgari on 13/06/2026.
//

//
//  PatientDashboardView.swift
//  awn app
//
//  The patient's home screen. Shows:
//   - Active caregivers who have accepted location access
//   - Pending requests to accept or decline
//   - Privacy controls (revoke access)
//   - Their own profile summary
//

import SwiftUI
import Combine

// MARK: - Patient Main View (tab container for patients)

struct PatientMainView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var selectedTab: PatientTab = .home

    enum PatientTab { case home, privacy, profile }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .home:    PatientDashboardView()
                case .privacy: PatientPrivacyView()
                case .profile: PatientProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom tab bar
            PatientTabBar(selected: $selectedTab)
        }
        .environmentObject(authViewModel)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Tab Bar

struct PatientTabBar: View {
    @Binding var selected: PatientMainView.PatientTab

    var body: some View {
        HStack(spacing: 0) {
            PatientTabButton(icon: "house.fill",        label: "Home",    tab: .home,    selected: $selected)
            PatientTabButton(icon: "hand.raised.fill",  label: "Privacy", tab: .privacy, selected: $selected)
            PatientTabButton(icon: "person.fill",       label: "Profile", tab: .profile, selected: $selected)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Color(hex: "1C1C1E")
                .overlay(Rectangle().frame(height: 0.5).foregroundColor(.white.opacity(0.08)), alignment: .top)
        )
    }
}

struct PatientTabButton: View {
    let icon: String
    let label: String
    let tab: PatientMainView.PatientTab
    @Binding var selected: PatientMainView.PatientTab

    var isSelected: Bool { selected == tab }

    var body: some View {
        Button(action: { selected = tab }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? Color(hex: "6C7CD1") : .white.opacity(0.35))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Patient Dashboard View

struct PatientDashboardView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var viewModel = PatientDashboardViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Background gradient
            VStack {
                ZStack {
                    Circle()
                        .fill(Color(hex: "6C7CD1").opacity(0.25))
                        .frame(width: 350, height: 350)
                        .offset(x: -160, y: -100)
                    Circle()
                        .fill(Color(hex: "8595E9").opacity(0.15))
                        .frame(width: 250, height: 250)
                        .offset(x: 100, y: -80)
                }
                Spacer()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    PatientDashboardHeader(
                        name: viewModel.patientName,
                        hasPending: !viewModel.pendingRequests.isEmpty,
                        hasActive: !viewModel.activeCaregivers.isEmpty
                    )
                    .padding(.top, 56)

                    // Pending requests section
                    if !viewModel.pendingRequests.isEmpty {
                        PendingRequestsSection(
                            requests: viewModel.pendingRequests,
                            onAccept: { viewModel.accept($0) },
                            onDecline: { viewModel.decline($0) }
                        )
                    }

                    // Active caregivers section
                    ActiveCaregiversSection(
                        caregivers: viewModel.activeCaregivers,
                        onRevoke: { viewModel.revoke($0) }
                    )

                    // No activity state
                    if viewModel.pendingRequests.isEmpty && viewModel.activeCaregivers.isEmpty && !viewModel.isLoading {
                        NoActivityCard()
                    }

                    // Today's Medications
                    if !viewModel.todayMedications.isEmpty {
                        PatientMedicationsSection(medications: viewModel.todayMedications)
                    }

                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 20)
            }
            .refreshable { await viewModel.refresh() }

            // Loading overlay
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                }
            }
        }
        .onAppear {
            let patientId = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.currentPatientID) ?? ""
            viewModel.load(patientId: patientId, name: nil)
        }
    }
}

// MARK: - Header

struct PatientDashboardHeader: View {
    let name: String
    let hasPending: Bool
    let hasActive: Bool

    var subtitle: String {
        if hasPending { return "You have a pending location request" }
        if hasActive  { return "Your location is being shared" }
        return "Your location is private"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hello, \(name.isEmpty ? "there" : name.components(separatedBy: " ").first ?? name) 👋")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text(subtitle)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

// MARK: - Pending Requests Section

struct PendingRequestsSection: View {
    let requests: [LocationSharingRequest]
    let onAccept: (LocationSharingRequest) -> Void
    let onDecline: (LocationSharingRequest) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                Text("Pending Requests")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(0.8)
                Text("\(requests.count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.orange.opacity(0.3)))
            }

            ForEach(requests) { request in
                IncomingRequestCard(
                    request: request,
                    onAccept: { onAccept(request) },
                    onDecline: { onDecline(request) }
                )
            }
        }
    }
}

// MARK: - Incoming Request Card

struct IncomingRequestCard: View {
    let request: LocationSharingRequest
    let onAccept: () -> Void
    let onDecline: () -> Void
    @State private var isResponding = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Who's asking
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "6C7CD1").opacity(0.15))
                        .frame(width: 46, height: 46)
                    Text(String(request.caregiverName.prefix(1)).uppercased())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "6C7CD1"))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(request.caregiverName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Requested \(request.requestedAt.timeAgoString())")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.45))
                }

                Spacer()

                Image(systemName: "location.circle")
                    .font(.system(size: 22))
                    .foregroundColor(.orange)
            }

            Text("This person is requesting access to see your location and whether you are inside your safe zone.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
                .lineSpacing(3)

            // Action buttons
            HStack(spacing: 10) {
                Button(action: {
                    isResponding = true
                    onDecline()
                }) {
                    Text("Decline")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.35), lineWidth: 1)
                        )
                }

                Button(action: {
                    isResponding = true
                    onAccept()
                }) {
                    HStack(spacing: 6) {
                        if isResponding {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        }
                        Text("Allow Access")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "6C7CD1"))
                    )
                }
                .disabled(isResponding)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.orange.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Active Caregivers Section

struct ActiveCaregiversSection: View {
    let caregivers: [LocationSharingRequest]
    let onRevoke: (LocationSharingRequest) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("Sharing Location With")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(0.8)
            }

            if caregivers.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "location.slash")
                        .foregroundColor(.white.opacity(0.2))
                    Text("Not sharing with anyone")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.vertical, 6)
            } else {
                ForEach(caregivers) { entry in
                    ActiveCaregiverRow(entry: entry, onRevoke: { onRevoke(entry) })
                }
            }
        }
    }
}

// MARK: - Active Caregiver Row

struct ActiveCaregiverRow: View {
    let entry: LocationSharingRequest
    let onRevoke: () -> Void
    @State private var showConfirm = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(String(entry.caregiverName.prefix(1)).uppercased())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.caregiverName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                    Text("Can see your location")
                        .font(.system(size: 12))
                        .foregroundColor(.green.opacity(0.8))
                }
            }

            Spacer()

            Button(action: { showConfirm = true }) {
                Text("Revoke")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.red.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(Color.red.opacity(0.25), lineWidth: 1)
                    )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.green.opacity(0.12), lineWidth: 1)
                )
        )
        .confirmationDialog(
            "Revoke access for \(entry.caregiverName)?",
            isPresented: $showConfirm,
            titleVisibility: .visible
        ) {
            Button("Revoke Access", role: .destructive) { onRevoke() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("They will no longer be able to see your location.")
        }
    }
}

// MARK: - No Activity Card

struct NoActivityCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 52))
                .foregroundColor(Color(hex: "6C7CD1").opacity(0.4))

            Text("Your location is private")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Text("No one is currently monitoring your location. When a caregiver sends a request, it will appear here.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

// MARK: - Patient Privacy View (tab 2)

struct PatientPrivacyView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var viewModel = PatientDashboardViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Settings")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 56)

                    // All sharing entries (pending + active + declined)
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(title: "All Requests")
                        ForEach(viewModel.allRequests) { request in
                            PrivacyRequestRow(request: request, onRevoke: {
                                viewModel.revoke(request)
                            })
                        }
                        if viewModel.allRequests.isEmpty {
                            Text("No location requests yet")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.3))
                                .padding(.vertical, 8)
                        }
                    }

                    // Privacy info card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(Color(hex: "6C7CD1"))
                            Text("Your Privacy")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Text("You are always in control. You can revoke location access at any time. Caregivers are notified that access has been removed.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.55))
                            .lineSpacing(3)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: "6C7CD1").opacity(0.07))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(hex: "6C7CD1").opacity(0.15), lineWidth: 1)
                            )
                    )

                    Color.clear.frame(height: 80)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            let patientId = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.currentPatientID) ?? ""
            viewModel.load(patientId: patientId, name: nil)
        }
    }
}

struct SectionLabel: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white.opacity(0.4))
            .textCase(.uppercase)
            .tracking(0.8)
    }
}

struct PrivacyRequestRow: View {
    let request: LocationSharingRequest
    let onRevoke: () -> Void

    var statusColor: Color {
        switch request.status {
        case .pending:  return .orange
        case .accepted: return .green
        case .declined: return .red.opacity(0.7)
        case .revoked:  return .gray
        }
    }

    var statusLabel: String {
        switch request.status {
        case .pending:  return "Pending"
        case .accepted: return "Has access"
        case .declined: return "Declined"
        case .revoked:  return "Revoked"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Text(String(request.caregiverName.prefix(1)).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(statusColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(request.caregiverName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                HStack(spacing: 4) {
                    Circle().fill(statusColor).frame(width: 6, height: 6)
                    Text(statusLabel)
                        .font(.system(size: 12))
                        .foregroundColor(statusColor)
                }
            }

            Spacer()

            if request.status == .accepted {
                Button("Revoke", action: onRevoke)
                    .font(.system(size: 13))
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
        )
    }
}

// MARK: - Patient Profile View (tab 3)

struct PatientProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    // Read patient's real name from UserDefaults (set during onboarding + synced from CloudKit)
    var displayName: String {
        UserDefaults.standard.string(forKey: "patientDisplayName") ?? "Patient"
    }

    var avatarLetter: String {
        String(displayName.prefix(1)).uppercased()
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer().frame(height: 60)

                // Avatar — uses patient's real name initial
                ZStack {
                    Circle()
                        .fill(Color(hex: "6C7CD1").opacity(0.15))
                        .frame(width: 90, height: 90)
                    Text(avatarLetter)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(hex: "6C7CD1"))
                }

                VStack(spacing: 6) {
                    Text(displayName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Text("Patient")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                }

                VStack(spacing: 0) {
                    ProfileRow(icon: "person.fill",
                               label: "Name",
                               value: displayName)
                    Divider().background(Color.white.opacity(0.07))
                    ProfileRow(icon: "envelope.fill",
                               label: "Email",
                               value: authViewModel.currentUser?.email ?? "—")
                    Divider().background(Color.white.opacity(0.07))
                    ProfileRow(icon: "shield.fill",
                               label: "Role",
                               value: "Patient")
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                )
                .padding(.horizontal, 20)

                Spacer()

                Button(action: {
                    // Clear patient-specific stored data on sign out
                    UserDefaults.standard.removeObject(forKey: "patientDisplayName")
                    authViewModel.signOut()
                }) {
                    Text("Sign Out")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 80)
            }
        }
    }
}

struct ProfileRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "6C7CD1"))
                .frame(width: 22)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Patient Medications Section

struct PatientMedicationsSection: View {
    let medications: [Medication]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Medications")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            ForEach(medications) { med in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "6C7CD1").opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: medIcon(med.medicationType))
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "6C7CD1"))
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(med.medicationName)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                        Text("\(med.dosage) · \(med.scheduledTimes.first ?? "")")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.04))
                )
            }
        }
    }

    private func medIcon(_ type: MedicationType) -> String {
        switch type {
        case .tablet:  return "pills.fill"
        case .capsule: return "capsule.fill"
        case .liquid:  return "drop.fill"
        case .topical: return "bandage.fill"
        case .other:   return "cross.fill"
        }
    }
}

// MARK: - Patient Dashboard ViewModel

final class PatientDashboardViewModel: ObservableObject {
    @Published var patientName: String = ""
    @Published var pendingRequests: [LocationSharingRequest] = []
    @Published var activeCaregivers: [LocationSharingRequest] = []
    @Published var allRequests: [LocationSharingRequest] = []
    @Published var todayMedications: [Medication] = []
    @Published var isLoading = false

    private var patientId: String = ""

    func load(patientId: String, name: String?) {
        self.patientId = patientId
        // Start with stored name immediately so UI isn't blank
        let storedName = UserDefaults.standard.string(forKey: "patientDisplayName")
        self.patientName = storedName ?? ""
        fetchPatientRecord()
        fetchAll()
        fetchMedications()
    }

    /// Fetch the Patient record from CloudKit to get the real name
    /// (avoids using Apple ID display name which may be a test account name)
    private func fetchPatientRecord() {
        guard !patientId.isEmpty, !patientId.hasPrefix("DEMO-") else { return }
        CloudKitManager.shared.fetchPatient(byID: patientId) { [weak self] result in
            if case .success(let patient) = result {
                DispatchQueue.main.async {
                    self?.patientName = patient.name
                    // Keep UserDefaults in sync
                    UserDefaults.standard.set(patient.name, forKey: "patientDisplayName")
                }
            }
        }
    }

    func fetchAll() {
        guard !patientId.isEmpty,
              !patientId.hasPrefix("DEMO-"),
              !DemoSession.shared.isActive else { return }

        isLoading = true

        // Fetch ALL requests for this patient (no status filter — avoids queryable index issue)
        CloudKitManager.shared.fetchPendingRequestsForPatient(patientId: patientId) { [weak self] result in
            self?.isLoading = false
            switch result {
            case .success(let requests):
                // fetchPendingRequestsForPatient already filters to .pending in CloudKit
                // We need all statuses — use a broader fetch here
                self?.pendingRequests = requests // pending only (from the existing method)
            case .failure(let error):
                print("❌ Patient dashboard fetch error: \(error.localizedDescription)")
            }
        }

        // Separately fetch accepted (active) caregivers
        fetchAccepted()
    }

    private func fetchAccepted() {
        // Uses caregiverId predicate — omit status so no queryable index needed
        // Then filter in memory to accepted
        let predicate = NSPredicate(format: "patientId == %@", patientId)
        let query = CKQuery(
            recordType: "LocationSharingRequest",
            predicate: predicate
        )

        let db = Constants.CloudKit.container.privateCloudDatabase
        db.perform(query, inZoneWith: nil) { [weak self] records, _ in
            guard let records = records else { return }
            let all = records.compactMap { LocationSharingRequest(from: $0) }
            DispatchQueue.main.async {
                self?.allRequests = all
                self?.activeCaregivers = all.filter { $0.status == .accepted }
                self?.pendingRequests = all.filter { $0.status == .pending }
            }
        }
    }

    @MainActor
    func refresh() async {
        await withCheckedContinuation { cont in
            fetchAll()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { cont.resume() }
        }
    }

    private func fetchMedications() {
        guard !patientId.isEmpty, !patientId.hasPrefix("DEMO-") else { return }
        CloudKitManager.shared.fetchMedications(for: patientId) { [weak self] result in
            if case .success(let meds) = result {
                let today = Calendar.current.component(.weekday, from: Date())
                let map: [Int: WeekDay] = [1:.sunday,2:.monday,3:.tuesday,4:.wednesday,5:.thursday,6:.friday,7:.saturday]
                let todayWD = map[today]
                DispatchQueue.main.async {
                    self?.todayMedications = meds.filter { med in
                        guard med.isActive else { return false }
                        switch med.frequencyType {
                        case .weekly:   return med.weekDays?.contains(todayWD ?? .monday) == true
                        case .interval, .asNeeded: return true
                        }
                    }
                }
            }
        }
    }

    func accept(_ request: LocationSharingRequest) {
        CloudKitManager.shared.updateLocationRequestStatus(
            requestId: request.id, newStatus: .accepted
        ) { [weak self] result in
            if case .success = result { self?.fetchAll() }
        }
    }

    func decline(_ request: LocationSharingRequest) {
        CloudKitManager.shared.updateLocationRequestStatus(
            requestId: request.id, newStatus: .declined
        ) { [weak self] result in
            if case .success = result { self?.fetchAll() }
        }
    }

    func revoke(_ request: LocationSharingRequest) {
        CloudKitManager.shared.updateLocationRequestStatus(
            requestId: request.id, newStatus: .revoked
        ) { [weak self] result in
            if case .success = result { self?.fetchAll() }
        }
    }
}

import CloudKit
