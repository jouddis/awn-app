//
//  UserRole.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//  User role enum for authentication
//

import Foundation

enum UserRole: String, Codable {
    case patient = "patient"
    case caregiver = "caregiver"
    
    var displayName: String {
        switch self {
        case .patient: return "Patient"
        case .caregiver: return "Caregiver"
        }
    }
}

