//import SwiftUI
//
//struct PendingLocationRequestOverlay: View {
//    let patientId: String
//
//    var body: some View {
//        ZStack {
//            Color.black.opacity(0.4)
//                .ignoresSafeArea()
//
//            VStack(spacing: 16) {
//                Text("Pending Location Request")
//                    .font(.title2)
//                    .fontWeight(.semibold)
//                    .foregroundColor(.primary)
//
//                Text("There is a pending location request for patient ID: \(patientId).")
//                    .font(.body)
//                    .multilineTextAlignment(.center)
//                    .foregroundColor(.secondary)
//
//                HStack(spacing: 24) {
//                    Button("Review") {
//                        print("Review tapped for patient ID: \(patientId)")
//                    }
//                    .buttonStyle(.borderedProminent)
//
//                    Button("Dismiss") {
//                        print("Dismiss tapped for patient ID: \(patientId)")
//                    }
//                    .buttonStyle(.bordered)
//                }
//            }
//            .padding(24)
//            .background(.regularMaterial)
//            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
//            .shadow(radius: 10)
//            .padding(.horizontal, 40)
//        }
//    }
//}
//
//#Preview {
//    PendingLocationRequestOverlay(patientId: "12345-ABCDE")
//}
