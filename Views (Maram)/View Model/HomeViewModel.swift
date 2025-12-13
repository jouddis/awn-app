//
//  HomeViewModel.swift
//  awaan test
//
//  Created by Maram on 22/06/1447 AH.
//

import SwiftUI
import Combine

class HomeViewModel: ObservableObject {
    @Published var userName: String = "Loading..."
    @Published var userImage: String = "memoji"
    @Published var hasLocation: Bool = false
    @Published var hasMedicines: Bool = false
    @Published var medicines: [Medicine] = []
    @Published var isPatientHome: Bool = true
    
    func fetchUserData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.userName = "Maram"
            self.userImage = "memoji"
            self.hasLocation = false
            self.hasMedicines = false
        }
    }
    
    func simulateAddLocation() {
        withAnimation { self.hasLocation = true }
    }
    
    func togglePatientLocation() {
            withAnimation {
                isPatientHome.toggle()
            }
        }
    
    // دالة المحاكاة مع الترتيب وأنواع الأدوية
    func simulateAddMedicines() {
        withAnimation {
            self.hasMedicines = true
            
            // نجهز تواريخ عشان الترتيب يضبط (صباح، ليل)
            let calendar = Calendar.current
            let now = Date()
            // 8:00 AM
            let morning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now)!
            // 10:00 PM
            let night = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: now)!
            
            var newMedicines = [
                // 1. حبة (Tablet) - الصباح
                Medicine(name: "Panadol", dosage: "1 Tablet", timeString: "8:00 AM", dateForSorting: morning, type: .tablet, isTaken: false, iconColor: Color("violate")),
                
                // 2. كبسولة (Capsule) - الليل
                Medicine(name: "Omega 3", dosage: "1 Capsule", timeString: "10:00 PM", dateForSorting: night, type: .assetImage("omega3"), isTaken: false, iconColor: .clear)            ]
            
            // الترتيب: اللي وقته قبل يجي فوق
            newMedicines.sort { $0.dateForSorting < $1.dateForSorting }
            
            self.medicines = newMedicines
        }
    }
    
    func toggleMedicine(id: UUID) {
        if let index = medicines.firstIndex(where: { $0.id == id }) {
            withAnimation(.spring()) {
                medicines[index].isTaken.toggle()
            }
        }
    }
}
