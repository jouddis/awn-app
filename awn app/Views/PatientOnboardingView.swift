//
//  PatientOnboardingView.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//

import SwiftUI

// MARK: - Main Onboarding Flow

struct PatientOnboardingView: View {
    @StateObject private var viewModel = PatientOnboardingViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            switch viewModel.currentStep {
            case .firstName:
                FirstNameView(viewModel: viewModel)
            case .relationship:
                RelationshipView(viewModel: viewModel)
            case .customRelationship:
                CustomRelationshipView(viewModel: viewModel)
            case .review:
                ReviewView(viewModel: viewModel)
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

// MARK: - Step 1: First Name

struct FirstNameView: View {
    @ObservedObject var viewModel: PatientOnboardingViewModel
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Top decoration
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .offset(x: -50, y: -50)
                Spacer()
            }
            
            Spacer()
            
            // Title
            Text("Let's make caring easier\ntogether")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.bottom, 60)
            
            // Input
            VStack(alignment: .leading, spacing: 12) {
                Text("First Name")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.blue.opacity(0.8))
                
                TextField("Write their name", text: $viewModel.firstName)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .focused($isTextFieldFocused)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Next button
            Button(action: {
                if !viewModel.firstName.isEmpty {
                    viewModel.moveToNextStep()
                }
            }) {
                Text("Next")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.firstName.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                    .cornerRadius(12)
            }
            .disabled(viewModel.firstName.isEmpty)
            .padding(.horizontal, 24)
            
            // Skip for now
            Button(action: {
                // Skip action
            }) {
                Text("Skip for now")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 20)
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

// MARK: - Step 2: Relationship Selection

struct RelationshipView: View {
    @ObservedObject var viewModel: PatientOnboardingViewModel
    
    let relationships = ["Son", "Daughter", "Other"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Top decoration
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .offset(x: -50, y: -50)
                Spacer()
            }
            
            Spacer()
            
            // Title
            Text("Let's make caring easier\ntogether")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
            
            // Name display
            Text(viewModel.firstName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 40)
            
            // Relationship prompt
            VStack(alignment: .leading, spacing: 16) {
                Text("Your relation with \(viewModel.firstName)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.blue.opacity(0.8))
                    .padding(.horizontal, 24)
                
                // Relationship buttons - Vertical layout
                VStack(spacing: 12) {
                    ForEach(relationships, id: \.self) { relation in
                        Button(action: {
                            viewModel.relationship = relation
                        }) {
                            HStack {
                                Text(relation)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if viewModel.relationship == relation {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(
                                viewModel.relationship == relation ?
                                Color.blue.opacity(0.2) : Color.white.opacity(0.05)
                            )
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Next button
            Button(action: {
                if !viewModel.relationship.isEmpty {
                    viewModel.moveToNextStep()
                }
            }) {
                Text("Next")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.relationship.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                    .cornerRadius(12)
            }
            .disabled(viewModel.relationship.isEmpty)
            .padding(.horizontal, 24)
            
            // Skip for now
            Button(action: {
                // Skip action
            }) {
                Text("Skip for now")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Step 3: Custom Relationship (if Other selected)

struct CustomRelationshipView: View {
    @ObservedObject var viewModel: PatientOnboardingViewModel
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Top decoration
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .offset(x: -50, y: -50)
                Spacer()
            }
            
            Spacer()
            
            // Title
            Text("Let's make caring easier\ntogether")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
            
            // Name display
            Text(viewModel.firstName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 40)
            
            // Custom relationship input
            VStack(alignment: .leading, spacing: 12) {
                Text("Tell us your relationship with \(viewModel.firstName)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.blue.opacity(0.8))
                
                TextField("Write your relation here", text: $viewModel.customRelationship)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .focused($isTextFieldFocused)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Next button
            Button(action: {
                if !viewModel.customRelationship.isEmpty {
                    viewModel.moveToNextStep()
                }
            }) {
                Text("Next")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.customRelationship.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                    .cornerRadius(12)
            }
            .disabled(viewModel.customRelationship.isEmpty)
            .padding(.horizontal, 24)
            
            // Skip for now
            Button(action: {
                // Skip action
            }) {
                Text("Skip for now")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

// MARK: - Step 4: Review

struct ReviewView: View {
    @ObservedObject var viewModel: PatientOnboardingViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Top decoration
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .offset(x: -50, y: -50)
                Spacer()
            }
            
            Spacer()
            
            // Title
            Text("Let's make caring easier\ntogether")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
            
            // Name display
            Text(viewModel.firstName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 40)
            
            // Relationship display
            VStack(alignment: .leading, spacing: 12) {
                Text("Your relation with \(viewModel.firstName)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.blue.opacity(0.8))
                
                Text(viewModel.displayRelationship)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Next button
            Button(action: {
                viewModel.moveToNextStep()
            }) {
                Text("Next")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            
            // Skip for now
            Button(action: {
                // Skip action
            }) {
                Text("Skip for now")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Step 5: Watch Pairing Info

struct WatchPairingInfoView: View {
    @ObservedObject var viewModel: PatientOnboardingViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Top decoration
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .offset(x: -50, y: -50)
                Spacer()
            }
            
            Spacer()
            
            // Title
            Text("Connect the Apple\nWatch")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.bottom, 40)
            
            // Instructions
            VStack(alignment: .leading, spacing: 16) {
                Text("Connect \(viewModel.firstName)'s Apple Watch to track her **movement** and **location** through Apple's family setup to continue benefiting from Awn")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            // Watch illustration
            Image(systemName: "applewatch")
                .font(.system(size: 120))
                .foregroundColor(.blue.opacity(0.6))
                .padding(.vertical, 60)
            
            Spacer()
            
            // Next button
            Button(action: {
                viewModel.moveToNextStep()
            }) {
                Text("I did family setup")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            
            // Skip link
            Button(action: {
                // Show help
            }) {
                Text("I'll do this later")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Step 6: Watch Pairing Visual

struct WatchPairingVisualView: View {
    @ObservedObject var viewModel: PatientOnboardingViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Top decoration
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .offset(x: -50, y: -50)
                Spacer()
            }
            
            Spacer()
            
            // Title
            Text("Connect the Apple\nWatch")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.bottom, 40)
            
            // Instructions
            Text("Make sure \(viewModel.firstName) always wearing her\nApple Watch")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Watch on wrist illustration
            ZStack {
                // Simple wrist outline
                RoundedRectangle(cornerRadius: 40)
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: 200, height: 80)
                
                // Watch
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 60, height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
            }
            .padding(.vertical, 80)
            
            Spacer()
            
            // Done button
            Button(action: {
                viewModel.completeOnboarding()
            }) {
                Text("Done !")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Step 7: Completed

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
                .tint(.blue)
                .padding(.top, 20)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    PatientOnboardingView()
}

