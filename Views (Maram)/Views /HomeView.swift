//
//  HomeView.swift
//  awaan test
//
//  Created by Maram on 22/06/1447 AH.
//

import SwiftUI
struct HomeView: View {
    
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                // Header
                HStack(spacing: 12) {
                    Image(viewModel.userImage).resizable().frame(width: 50, height: 50).clipShape(Circle())
                    Text("Hello \(viewModel.userName)").font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                    Spacer()
                    Button(action: { }) {
                        Circle().fill(Color.black).frame(width: 45, height: 45)
                            .overlay(Image(systemName: "bell.fill").foregroundColor(Color(hex: "6C7CD1")))
                            .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .shadow(color: Color.white.opacity(0.1), radius: 5)
                    }
                }
                .padding(.horizontal).padding(.top, 10)
                
                // ScrollView
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // 1. Location Section
                        if viewModel.hasLocation {
                            VStack(spacing: 15) {
                                // هنا التعديل: نمرر حالة المريض للكرت
                                StatusCardView(isHome: viewModel.isPatientHome)
                                    .onTapGesture {
                                        // عند الضغط على الكرت، نغير الحالة للتجربة
                                        viewModel.togglePatientLocation()
                                    }
                                
                                FallDetectionCard()
                            }
                        } else {
                            HomeCardView(
                                iconName: "mappin.and.ellipse", iconColor: Color(hex: "6C7CD1"),
                                title: "Add Patient Location", subtitle: "To enable tracking, please add the location.",
                                buttonText: "Add Location"
                            ) { viewModel.simulateAddLocation() }
                        }
                        
                        // 2. Medicines Section
                        if viewModel.hasMedicines {
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Text("Medications").font(.title2).fontWeight(.bold).foregroundColor(.white)
                                    Spacer()
                                    Button("Show All") { }.font(.subheadline).foregroundColor(.gray)
                                }
                                .padding(.horizontal, 5)
                                
                                VStack(spacing: 0) {
                                    ForEach(Array(viewModel.medicines.enumerated()), id: \.element.id) { index, medicine in
                                        MedicineRowView(medicine: medicine) { viewModel.toggleMedicine(id: medicine.id) }
                                        if index < viewModel.medicines.count - 1 {
                                            Divider().background(Color.white.opacity(0.1)).padding(.leading, 70)
                                        }
                                    }
                                }
                                .background(Color(hex: "1C1C1E")).cornerRadius(22)
                            }
                            .padding(.horizontal)
                        } else {
                            HomeCardView(
                                iconName: "pills.fill", iconColor: Color(hex: "8595E9"),
                                title: "Add Patient Medicines", subtitle: "Add medicines to enable notifications.",
                                buttonText: "Add Medicines"
                            ) { viewModel.simulateAddMedicines() }
                        }
                    }
                    .padding(.horizontal).padding(.top, 10).padding(.bottom, 100)
                }
            }
            
            VStack { Spacer(); CustomTabBar() }
        }
        .onAppear { viewModel.fetchUserData() }
    }
}

// MARK: - 4. Sub-Views

struct StatusCardView: View {
    var isHome: Bool // نستقبل الحالة هنا
    
    var statusColor: Color { isHome ? .green : .orange }
    var locationText: String { isHome ? "Home" : "Outside" }
    var badgeIcon: String { isHome ? "checkmark.circle.fill" : "exclamationmark.circle.fill" }
    var statusLabel: String { isHome ? "Safe Zone" : "Roaming" }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Watch Status")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(alignment: .center, spacing: 15) {
                
                // 1. الأيقونة
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "6C7CD1").opacity(0.2))
                            .frame(width: 50, height: 50)
                        Image(systemName: "applewatch.side.right")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "6C7CD1"))
                    }
                    // Badge (صح أخضر أو تنبيه برتقالي)
                    Image(systemName: badgeIcon)
                        .font(.system(size: 16))
                        .foregroundColor(statusColor)
                        .background(Color.black.clipShape(Circle()))
                        .offset(x: 5, y: 5)
                }
                
                // 2. النصوص
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current place")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(locationText) // Home أو Outside
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(isHome ? .white : .orange) // لو طلع يصير برتقالي
                }
                
                Spacer()
                
                // 3. الحالة
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "battery.100").foregroundColor(.white)
                        Text("87%").font(.caption).foregroundColor(.white)
                    }
                    
                    Text(statusLabel) // Safe Zone أو Roaming
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(hex: "1C1C1E")))
    }
}


struct MedicineRowView: View {
    let medicine: Medicine
    var onToggle: () -> Void
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 18).fill(Color(hex: "2C2C2E")).frame(width: 55, height: 55)
                switch medicine.type {
                case .tablet:
                    Circle().fill(LinearGradient(colors: [.white, medicine.iconColor], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 28).shadow(color: medicine.iconColor.opacity(0.4), radius: 2)
                case .capsule:
                    ZStack {
                        Capsule().fill(Color.white).frame(width: 18, height: 32).offset(y: -5)
                        Capsule().fill(LinearGradient(colors: [medicine.iconColor.opacity(0.6), medicine.iconColor], startPoint: .top, endPoint: .bottom)).frame(width: 18, height: 16).offset(y: 5).clipShape(Rectangle().offset(y: 5))
                    }.rotationEffect(.degrees(-30))
                case .liquid:
                    Image(systemName: "drop.fill").font(.system(size: 26)).foregroundStyle(LinearGradient(colors: [.white, medicine.iconColor], startPoint: .top, endPoint: .bottom))
                case .assetImage(let imageName):
                    Image("Cap").resizable().aspectRatio(contentMode: .fit).frame(width: 35, height: 35).shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(medicine.name).font(.body).fontWeight(.bold).foregroundColor(.white)
                Text("\(medicine.dosage), \(medicine.timeString)").font(.subheadline).foregroundColor(.gray)
            }
            Spacer()
            Button(action: onToggle) {
                ZStack {
                    Circle().fill(medicine.isTaken ? Color(hex: "5E5CE6") : Color(hex: "2C2C2E")).frame(width: 30, height: 30)
                    if medicine.isTaken { Image(systemName: "checkmark").font(.system(size: 14, weight: .bold)).foregroundColor(.white) }
                }
            }
        }
        .padding(16)
    }
}

struct FallDetectionCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Fall Detection").font(.headline).foregroundColor(.white)
            HStack(spacing: 15) {
                Image(systemName: "exclamationmark.triangle.fill").resizable().aspectRatio(contentMode: .fit).frame(width: 40, height: 40).foregroundColor(Color(hex: "8595E9"))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Detected").font(.title3).fontWeight(.semibold).foregroundColor(.white)
                    Text("in the last 24 hours").font(.subheadline).foregroundColor(.gray)
                }
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                    Text("Enabled").font(.subheadline).foregroundColor(.white)
                }
            }
        }
        .padding(20).background(RoundedRectangle(cornerRadius: 24).fill(Color(hex: "1C1C1E")))
    }
}

struct HomeCardView: View {
    var iconName: String; var iconColor: Color; var title: String; var subtitle: String; var buttonText: String; var action: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top) {
                Image(systemName: iconName).resizable().aspectRatio(contentMode: .fit).frame(width: 40, height: 40).foregroundColor(iconColor)
                Spacer()
            }
            Text(title).font(.title2).fontWeight(.bold).foregroundColor(.white)
            Text(subtitle).font(.body).foregroundColor(.gray).fixedSize(horizontal: false, vertical: true).lineSpacing(4)
            Button(action: action) {
                Text(buttonText).fontWeight(.semibold).frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color(hex: "6C7CD1")).foregroundColor(.white).cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.22), radius: 0.1, x: 0.7, y: 0.5)
                    .shadow(color: Color.white.opacity(0.22), radius: 0.6, x: -0.5, y: -0.5)
            }
            .padding(.top, 10)
        }
        .padding(20).background(RoundedRectangle(cornerRadius: 24).fill(Color(hex: "1C1C1E")).overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.08), lineWidth: 1)))
    }
}

struct CustomTabBar: View {
    var body: some View {
        HStack {
            TabBarItem(icon: "house.fill", text: "Home", isSelected: true)
            Spacer()
            TabBarItem(icon: "location.fill", text: "Location", isSelected: false)
            Spacer()
            TabBarItem(icon: "pills.fill", text: "Medicines", isSelected: false)
        }
        .padding(.horizontal, 12).padding(.vertical, 5)
        .background(ZStack { Capsule().fill(.black); Capsule().fill(Color(hex: "6C7CD1").opacity(0.19)) }
            .shadow(color: Color.white.opacity(0.1), radius: 5, x: 0, y: -2)
            .shadow(color: Color.black.opacity(10), radius: 0.2, x: 0.4, y: 0.5)
            .shadow(color: Color.white.opacity(5), radius: 0.2, x: -0.5, y: -0.5))
        .padding(.horizontal).padding(.bottom, 12)
    }
}

struct TabBarItem: View {
    var icon: String; var text: String; var isSelected: Bool
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 22))
            Text(text).font(.caption2)
        }
        .foregroundColor(isSelected ? (Color(hex: "6C7CD1")): .gray).padding(.horizontal, 33).padding(.vertical, 8)
        .background(isSelected ? .black : Color.clear).cornerRadius(44)
    }
}


#Preview {
    HomeView()
}
