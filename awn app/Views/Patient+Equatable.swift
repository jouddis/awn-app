//
//  Patient+Equatable.swift
//  awn app
//
//  Created by Joud Almashgari on 12/06/2026.
//

//
//  Patient+Equatable.swift
//  awn app
//
//  Adds Equatable conformance so SwiftUI's onChange(of: viewModel.currentPatient) compiles.
//

import Foundation

extension Patient: Equatable {
    static func == (lhs: Patient, rhs: Patient) -> Bool {
        lhs.id == rhs.id
    }
}
