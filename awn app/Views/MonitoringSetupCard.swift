//
//  MonitoringSetupCard.swift
//  awn app
//
//  Created by Joud Almashgari on 13/06/2026.
//

//
//  MonitoringSetupCard.swift
//  awn app
//

import SwiftUI

struct MonitoringSetupCard: View {
    let readiness: MonitoringReadiness
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            Button(action: { withAnimation(.spring(response: 0.35)) { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    // Status icon
                    Image(systemName: readiness.level.icon)
                        .font(.system(size: 20))
                        .foregroundColor(readiness.level.color)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Monitoring Setup")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Text("\(readiness.score)/5 complete · \(readiness.level.label)")
                            .font(.system(size: 12))
                            .foregroundColor(readiness.level.color)
                    }

                    Spacer()

                    // Progress ring
                    ProgressRing(value: readiness.percentage)
                        .frame(width: 36, height: 36)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            // Expanded checklist
            if isExpanded {
                Divider().background(Color.white.opacity(0.08))

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(readiness.items) { item in
                        ReadinessRow(item: item)
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(readiness.level.color.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

// MARK: - Progress Ring

private struct ProgressRing: View {
    let value: Int // 0-100

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 4)
            Circle()
                .trim(from: 0, to: CGFloat(value) / 100)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.5), value: value)
            Text("\(value)%")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    var ringColor: Color {
        switch value {
        case 80...100: return .green
        case 40..<80:  return .orange
        default:       return .red
        }
    }
}

// MARK: - Row

private struct ReadinessRow: View {
    let item: ReadinessItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16))
                .foregroundColor(item.done ? .green : .white.opacity(0.25))
                .frame(width: 20)

            Text(item.done ? item.label : missingLabel(item.label))
                .font(.system(size: 13))
                .foregroundColor(item.done ? .white.opacity(0.75) : .white.opacity(0.45))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
    }

    // Turn "Watch Paired" → "Watch Not Paired" when false
    private func missingLabel(_ label: String) -> String {
        switch label {
        case "Patient Linked":               return "No Patient Linked"
        case "Location Sharing Accepted":    return "Awaiting Patient Approval"
        case "Watch Paired":                 return "Watch Not Paired"
        case "Location Permission Granted":  return "Location Permission Missing"
        case "First Location Received":      return "Waiting for First Location"
        default:                             return label
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 16) {
            MonitoringSetupCard(readiness: .empty)
            MonitoringSetupCard(readiness: MonitoringReadiness(
                patientLinked: true, locationSharingAccepted: true,
                watchPaired: false, locationPermission: false, firstLocationReceived: false
            ))
            MonitoringSetupCard(readiness: .fullDemo)
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
