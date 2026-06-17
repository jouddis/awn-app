//
//  MedicationListView.swift
//  awn app
//
//  Created by Joud Almashgari on 13/06/2026.
//

//
//  MedicationListView.swift
//  awn app
//

import SwiftUI
import Combine

struct MedicationListView: View {
    @StateObject private var viewModel = MedicationListViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Medications")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if viewModel.isDemoMode {
                        DemoBadge()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else if viewModel.medications.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Today section
                            if !viewModel.todayMeds.isEmpty {
                                SectionHeader(title: "Today")
                                ForEach(viewModel.todayMeds) { med in
                                    MedicationRow(medication: med)
                                }
                            }

                            // All active medications
                            SectionHeader(title: "All Medications")
                            ForEach(viewModel.medications) { med in
                                MedicationRow(medication: med)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { viewModel.load(isDemoMode: DemoSession.shared.isActive) }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "pills.fill")
                .font(.system(size: 52))
                .foregroundColor(Color(hex: "6C7CD1").opacity(0.5))
            Text("No Medications Added")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            Text("Medications added during onboarding will appear here.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

// MARK: - ViewModel

final class MedicationListViewModel: ObservableObject {
    @Published var medications: [Medication] = []
    @Published var todayMeds: [Medication] = []
    @Published var isLoading = false
    @Published var isDemoMode = false

    func load(isDemoMode: Bool) {
        self.isDemoMode = isDemoMode
        if isDemoMode {
            medications = DemoDataProvider.medications
            todayMeds   = DemoDataProvider.medications.filter { isScheduledToday($0) }
            return
        }
        // Real data — fetch from CloudKit via patientID stored in UserDefaults
        guard let patientID = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.currentPatientID) else { return }
        isLoading = true
        CloudKitManager.shared.fetchMedications(for: patientID) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                if case .success(let meds) = result {
                    self?.medications = meds.filter { $0.isActive }
                    self?.todayMeds   = meds.filter { $0.isActive && (self?.isScheduledToday($0) ?? false) }
                }
            }
        }
    }

    private func isScheduledToday(_ med: Medication) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: Date())
        let map: [Int: WeekDay] = [1:.sunday,2:.monday,3:.tuesday,4:.wednesday,5:.thursday,6:.friday,7:.saturday]
        guard let today = map[weekday] else { return false }
        switch med.frequencyType {
        case .weekly:   return med.weekDays?.contains(today) == true
        case .interval: return true
        case .asNeeded: return true
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
                .textCase(.uppercase)
                .tracking(1)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 6)
    }
}

// MARK: - Medication Row

struct MedicationRow: View {
    let medication: Medication

    var body: some View {
        HStack(spacing: 14) {
            // Type icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: typeIcon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(medication.medicationName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 6) {
                    Text(medication.dosage)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                    Text("·")
                        .foregroundColor(.white.opacity(0.3))
                    Text(timesText)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                ForEach(medication.scheduledTimes.prefix(2), id: \.self) { time in
                    Text(time)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "6C7CD1"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(Color(hex: "6C7CD1").opacity(0.15))
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.03))
        )
        Divider().background(Color.white.opacity(0.06)).padding(.leading, 78)
    }

    private var typeIcon: String {
        switch medication.medicationType {
        case .tablet:  return "pills.fill"
        case .capsule: return "capsule.fill"
        case .liquid:  return "drop.fill"
        case .topical: return "bandage.fill"
        case .other:   return "cross.fill"
        }
    }

    private var iconColor: Color {
        switch medication.medicationType {
        case .tablet:  return Color(hex: "6C7CD1")
        case .capsule: return .orange
        case .liquid:  return .blue
        case .topical: return .green
        case .other:   return .gray
        }
    }

    private var timesText: String {
        switch medication.frequencyType {
        case .weekly:   return "Weekly"
        case .interval: return "Every \(medication.intervalDays ?? 1) day(s)"
        case .asNeeded: return "As needed"
        }
    }
}

// MARK: - Demo Badge

struct DemoBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 11))
            Text("DEMO")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
        }
        .foregroundColor(.orange)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.orange.opacity(0.15)))
        .overlay(Capsule().stroke(Color.orange.opacity(0.3), lineWidth: 1))
    }
}

#Preview {
    MedicationListView()
        .environmentObject(AuthenticationViewModel())
}
