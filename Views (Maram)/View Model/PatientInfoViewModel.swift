//
//  PatientInfoViewModel.swift
//  awaan test
//
//  Created by Maram on 21/06/1447 AH.
//

import SwiftUI
import Combine

class PatientInfoViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var selectedRelation: String = ""
    @Published var otherRelationDetails: String = ""
    
    var isFormValid: Bool {
        let nameValid = !name.trimmingCharacters(in: .whitespaces).isEmpty
        let relationSelected = !selectedRelation.isEmpty
        let otherValid = selectedRelation == "Other" ? !otherRelationDetails.trimmingCharacters(in: .whitespaces).isEmpty : true
        
        return nameValid && relationSelected && otherValid
    }
    
    // دالة الإرسال (هنا يكتبون كود إرسال البيانات)
    func submitData() {
        print("Submitting data...")
        // API Call here...
    }
}
