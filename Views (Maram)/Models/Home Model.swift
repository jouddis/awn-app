//
//  Home Model.swift
//  awaan test
//
//  Created by Maram on 22/06/1447 AH.
//
import SwiftUI
import Combine

enum MedicineIconType {
    case tablet
    case capsule
    case liquid
    case assetImage(String)
}

struct Medicine: Identifiable {
    let id = UUID()
    let name: String
    let dosage: String
    let timeString: String // الوقت للعرض (نص)
    let dateForSorting: Date // التاريخ الحقيقي (للترتيب)
    let type: MedicineIconType // نوع الدواء (للرسم)
    var isTaken: Bool
    var iconColor: Color
}
