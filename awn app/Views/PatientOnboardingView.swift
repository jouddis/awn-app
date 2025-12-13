//
//  PatientOnboardingView.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//
//
//
//
import SwiftUI

// MARK: - Color Extension for Hex

//extension Color {
//    init(hex: String) {
//        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
//        var int: UInt64 = 0
//        Scanner(string: hex).scanHexInt64(&int)
//        let a, r, g, b: UInt64
//        switch hex.count {
//        case 3: // RGB (12-bit)
//            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
//        case 6: // RGB (24-bit)
//            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
//        case 8: // ARGB (32-bit)
//            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
//        default:
//            (a, r, g, b) = (1, 1, 1, 0)
//        }
//
//        self.init(
//            .sRGB,
//            red: Double(r) / 255,
//            green: Double(g) / 255,
//            blue:  Double(b) / 255,
//            opacity: Double(a) / 255
//        )
//    }
//}

// MARK: - Main Onboarding Flow

struct PatientOnboardingView: View {
    @StateObject private var viewModel = PatientOnboardingViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(.keyboard)
            
            switch viewModel.currentStep {
            case .firstName, .relationship, .customRelationship, .review:
                // All combined into one screen
                PatientInfoView(viewModel: viewModel)
                
            case .watchPairingInfo:
                WatchPairingInfoView(viewModel: viewModel)
                
            case .watchPairingVisual:
                WatchPairingVisualView(viewModel: viewModel)
                
            case .completed:
                CompletedView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Combined Patient Info View (FIXED - Keyboard & Performance)

struct PatientInfoView: View {
    @ObservedObject var viewModel: PatientOnboardingViewModel
    @FocusState private var focusedField: Field?
    
    enum Field {
        case patientName
        case customRelation
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // الفريم البنفسجي اللي ورا
            VStack {
                ZStack{
                    RoundedRectangle(cornerRadius: 34)
                        .fill(Color(hex: "8B5CF6").opacity(0.20))
                        .frame(height: 330)
                        .offset(x: 0, y: -122)
                        .shadow(color: Color.black.opacity(22), radius: 0.1, x: 0, y: -0.4)
                        .shadow(color: Color.white.opacity(22), radius: 0.12, x: -0.5, y: -0.12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 35)
                                .stroke(Color.white.opacity(0.05), lineWidth: 4)
                                .shadow(color: Color.white.opacity(0.12), radius: 2, x: 22, y: 33)
                                .shadow(color: Color.white.opacity(0.12), radius: 0.6, x: 0.5, y: 0)
                                .offset(x: 0, y: -122)
                        )
                    
                    Circle()
                        .fill(Color(hex: "6C7CD1").opacity(0.37))
                        .frame(width: 400, height: 460)
                        .offset(x: -300, y: -30)
                        .rotationEffect(.degrees(50))
                    
                    Circle()
                        .fill(Color(hex: "8595E9").opacity(0.62))
                        .frame(width: 270, height: 400)
                        .offset(x: -366, y: -22)
                        .rotationEffect(.degrees(50))
                }
                
                Spacer()
            }
            
            // Scrollable content - FIXED
            ScrollView {
                VStack(spacing: 20) {
                    // Title
                    Text("Let's make caring easier\ntogether")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.top, 100)
                    
                    Color.clear.frame(height: 100)
                    
                    // Patient Name Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Patient Name")
                            .foregroundColor(Color(hex: "6C7CD1"))
                            .font(.system(size: 18, weight: .medium))
                        
                        TextField("Type patient name here", text: $viewModel.firstName)
                            .focused($focusedField, equals: .patientName)
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.35))
                                    .shadow(color: Color.black.opacity(0.22), radius: 0.1, x: 0.7, y: 0.5)
                                    .shadow(color: Color.white.opacity(0.22), radius: 0.6, x: -0.5, y: -0.5)
                            )
                        
                        // Relationship Section
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Your relation with Patient")
                                .foregroundColor(Color(hex: "6C7CD1"))
                                .font(.system(size: 18, weight: .medium))
                                .padding(.top, 18)
                            
                            // Relationship Buttons
                            HStack(spacing: 22) {
                                ForEach(["Son", "Daughter", "Other"], id: \.self) { title in
                                    Button(action: {
                                        withAnimation {
                                            viewModel.relationship = title
                                            focusedField = nil // Dismiss keyboard
                                        }
                                    }) {
                                        Text(title)
                                            .foregroundColor(.white)
                                            .font(.system(size: 17, weight: .medium))
                                            .padding(.vertical, 15)
                                            .frame(maxWidth: .infinity)
                                            .glassEffect()
                                            .background(
                                                RoundedRectangle(cornerRadius: 34)
                                                    .fill(
                                                        viewModel.relationship == title
                                                        ? Color(hex: "6C7CD1").opacity(0.6)
                                                        : Color.black.opacity(0.35)
                                                    )
                                                    .shadow(color: Color.black.opacity(22), radius: 0.1, x: 0.7, y: 0.5)
                                                    .shadow(color: Color.white.opacity(22), radius: 0.6, x: -0.5, y: -0.5)
                                            )
                                    }
                                }
                            }
                            
                            // Custom Relationship Input
                            if viewModel.relationship == "Other" {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Please specify")
                                        .foregroundColor(Color(hex: "6C7CD1"))
                                        .font(.system(size: 18, weight: .medium))
                                        .padding(.top, 5)
                                    
                                    TextField("Type relation here", text: $viewModel.customRelationship)
                                        .focused($focusedField, equals: .customRelation)
                                        .foregroundColor(.white)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.words)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.black.opacity(0.35))
                                                .shadow(color: Color.black.opacity(0.22), radius: 0.1, x: 0.7, y: 0.5)
                                                .shadow(color: Color.white.opacity(0.22), radius: 0.6, x: -0.5, y: -0.5)
                                        )
                                }
                                .transition(.opacity)
                            }
                        }
                    }
                    .padding()
                    .padding(.top, -36)
                    
                    // Extra padding for keyboard
                    Color.clear.frame(height: 350)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            
            // Fixed Next Button at bottom
            VStack {
                Spacer()
                
                Button(action: {
                    focusedField = nil // Dismiss keyboard
                    if isFormValid {
                        viewModel.currentStep = .watchPairingInfo
                    }
                }) {
                    Text("Next")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .bold))
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isFormValid ? Color(hex: "6C7CD1").opacity(0.6) : Color.black.opacity(0.35))
                                .shadow(color: Color.black.opacity(22), radius: 0.1, x: 0.7, y: 0.5)
                                .shadow(color: Color.white.opacity(22), radius: 0.6, x: -0.5, y: -0.5)
                        )
                }
                .disabled(!isFormValid)
                .animation(.easeInOut, value: isFormValid)
                .padding(.horizontal, 30)
                .padding(.bottom, 33)
                .background(Color.black) // Solid background
            }
        }
    }
    
    // Validation logic
    private var isFormValid: Bool {
        guard !viewModel.firstName.isEmpty else { return false }
        guard !viewModel.relationship.isEmpty else { return false }
        
        if viewModel.relationship == "Other" {
            return !viewModel.customRelationship.isEmpty
        }
        
        return true
    }
}

// MARK: - Watch Pairing Info View

struct WatchPairingInfoView: View {
    @ObservedObject var viewModel: PatientOnboardingViewModel
    @State private var showFamilySharingSheet = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Purple gradient background
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 34)
                        .fill(Color(hex: "8B5CF6").opacity(0.20))
                        .frame(height: 330)
                        .offset(x: 0, y: -122)
                        .shadow(color: Color.black.opacity(0.22), radius: 0.1, x: 0, y: -0.4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 35)
                                .stroke(Color.white.opacity(0.05), lineWidth: 4)
                                .offset(x: 0, y: -122)
                        )
                    
                    Circle()
                        .fill(Color(hex: "6C7CD1").opacity(0.37))
                        .frame(width: 400, height: 460)
                        .offset(x: -300, y: -30)
                        .rotationEffect(.degrees(50))
                    
                    Circle()
                        .fill(Color(hex: "8595E9").opacity(0.62))
                        .frame(width: 270, height: 400)
                        .offset(x: -366, y: -22)
                        .rotationEffect(.degrees(50))
                }
                
                Spacer()
            }
            
            VStack(spacing: 20) {
                // Title
                Text("Connect the Apple\nWatch")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 100)
                
                // Instructions
                Text(instructionsText)
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 40)
                
                // Watch illustration
                Image(systemName: "applewatch")
                    .font(.system(size: 120))
                    .foregroundColor(Color(hex: "6C7CD1").opacity(0.6))
                    .padding(.vertical, 60)
                
                Spacer()
                
                // I did family setup button
                Button(action: {
                    viewModel.currentStep = .watchPairingVisual
                }) {
                    Text("I did family setup")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "6C7CD1").opacity(0.6))
                                .shadow(color: Color.black.opacity(0.22), radius: 0.1, x: 0.7, y: 0.5)
                                .shadow(color: Color.white.opacity(0.22), radius: 0.6, x: -0.5, y: -0.5)
                        )
                }
                .padding(.horizontal, 30)
                
                // I'll do this later - Opens the sheet
                Button(action: {
                    showFamilySharingSheet = true
                }) {
                    Text("I'll do this later")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.top, 12)
                .padding(.bottom, 33)
            }
        }
        .sheet(isPresented: $showFamilySharingSheet) {
            FamilySharingInstructionsSheet(
                patientName: viewModel.firstName,
                showSheet: $showFamilySharingSheet
            )
        }
    }
    
    // Create AttributedString for instructions with colored text
    private var instructionsText: AttributedString {
        var result = AttributedString("Connect \(viewModel.firstName)'s Apple Watch to track her location ")
        result.foregroundColor = .white.opacity(0.8)
        
        var familySetup = AttributedString("via family set up")
        familySetup.foregroundColor = Color(hex: "6C7CD1")
        
        var ending = AttributedString(" to continue benefiting from Awn")
        ending.foregroundColor = .white.opacity(0.8)
        
        result.append(familySetup)
        result.append(ending)
        
        return result
    }
}

// MARK: - Family Sharing Instructions Sheet (FIXED - Watch App URL)

struct FamilySharingInstructionsSheet: View {
    let patientName: String
    @Binding var showSheet: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Drag indicator
                Capsule()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                // Header with purple gradient
                ZStack {
                    Circle()
                        .fill(Color(hex: "6C7CD1").opacity(0.3))
                        .frame(width: 200, height: 200)
                        .offset(x: -100, y: -50)
                    
                    Circle()
                        .fill(Color(hex: "8595E9").opacity(0.4))
                        .frame(width: 150, height: 150)
                        .offset(x: -150, y: -30)
                    
                    VStack(spacing: 16) {
                        Text("Connect the Apple\nWatch")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                }
                .frame(height: 180)
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Family Sharing")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 20)
                        
                        VStack(spacing: 8) {
                            Text(attributedDescription)
                                .font(.system(size: 16))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 20)
                        
                        // Steps
                        VStack(alignment: .leading, spacing: 20) {
                            InstructionStep(
                                icon: "gearshape.fill",
                                iconColor: Color(hex: "6C7CD1"),
                                text: "1. Open your iPhone Settings"
                            )
                            
                            InstructionStep(
                                icon: "person.circle.fill",
                                iconColor: Color(hex: "6C7CD1"),
                                text: "2. Tap on your Apple ID"
                            )
                            
                            InstructionStep(
                                icon: "person.2.fill",
                                iconColor: Color(hex: "6C7CD1"),
                                text: "3. Then add Family Members"
                            )
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 20)
                    }
                }
                
                Spacer()
                
                // Open Watch App button - FIXED
                Button(action: {
                    openWatchApp()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "applewatch")
                            .font(.system(size: 20))
                        Text("Open Watch App")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "6C7CD1").opacity(0.8))
                    )
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // Create AttributedString with clickable link
    private var attributedDescription: AttributedString {
        var result = AttributedString("Enable Family Sharing from the settings on your device to track the patient's location. To learn more, please ")
        result.foregroundColor = .white.opacity(0.7)
        
        var link = AttributedString("visit link")
        link.foregroundColor = Color(hex: "6C7CD1")
        link.underlineStyle = .single
        link.link = URL(string: "https://support.apple.com/en-sa/109036")
        
        result.append(link)
        
        return result
    }
    
    // FIXED - Multiple URL schemes for Watch app
    private func openWatchApp() {
        let watchURLSchemes = [
            "watch://",           // Primary Watch app scheme
            "itms-watch://",      // Alternative scheme
            "com.apple.Bridge://" // Bridge app scheme
        ]
        
        var opened = false
        for scheme in watchURLSchemes {
            if let url = URL(string: scheme) {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                    opened = true
                    break
                }
            }
        }
        
        // Fallback: Open Watch settings
        if !opened {
            if let settingsURL = URL(string: "App-prefs:root=WATCH") {
                if UIApplication.shared.canOpenURL(settingsURL) {
                    UIApplication.shared.open(settingsURL)
                } else {
                    // Final fallback: General Settings
                    if let generalSettings = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(generalSettings)
                    }
                }
            }
        }
    }
}

// MARK: - Instruction Step Component

struct InstructionStep: View {
    let icon: String
    let iconColor: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 30)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

// MARK: - Watch Pairing Visual View

struct WatchPairingVisualView: View {
    @ObservedObject var viewModel: PatientOnboardingViewModel
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Purple gradient background
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 34)
                        .fill(Color(hex: "8B5CF6").opacity(0.20))
                        .frame(height: 330)
                        .offset(x: 0, y: -122)
                    
                    Circle()
                        .fill(Color(hex: "6C7CD1").opacity(0.37))
                        .frame(width: 400, height: 460)
                        .offset(x: -300, y: -30)
                        .rotationEffect(.degrees(50))
                    
                    Circle()
                        .fill(Color(hex: "8595E9").opacity(0.62))
                        .frame(width: 270, height: 400)
                        .offset(x: -366, y: -22)
                        .rotationEffect(.degrees(50))
                }
                
                Spacer()
            }
            
            VStack(spacing: 20) {
                Text("Connect the Apple\nWatch")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 100)
                
                Text("Make sure \(viewModel.firstName) is always wearing the\nApple Watch")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 40)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 40)
                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 200, height: 80)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "6C7CD1").opacity(0.3))
                        .frame(width: 60, height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "6C7CD1"), lineWidth: 2)
                        )
                }
                .padding(.vertical, 80)
                
                Spacer()
                
                Button(action: {
                    viewModel.completeOnboarding()
                }) {
                    Text("Done !")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "6C7CD1").opacity(0.6))
                                .shadow(color: Color.black.opacity(0.22), radius: 0.1, x: 0.7, y: 0.5)
                        )
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 33)
            }
        }
    }
}

// MARK: - Completed View

struct CompletedView: View {
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Setup Complete!")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, 20)
            
            Text("Verifying patient data...")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .padding(.top, 8)
            
            ProgressView()
                .tint(Color(hex: "6C7CD1"))
                .padding(.top, 20)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    PatientOnboardingView()
}
