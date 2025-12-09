//
//  SafeZoneView.swift
//  awn app
//
//  Created by Joud Almashgari on 09/12/2025.
//

import SwiftUI
import MapKit

// MARK: - Main View

struct SafeZoneView: View {
    @StateObject private var viewModel = SafeZoneViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                LocationHeader(onBack: { dismiss() })
                
                // Content based on state
                if viewModel.isLoading {
                    LoadingStateView()
                } else if !viewModel.hasPatient {
                    NoPatientStateView()
                } else {
                    // Main content
                    contentView
                }
            }
            
            // Success alert overlay
            if viewModel.showSuccessAlert {
                SuccessAlertView(
                    zoneName: viewModel.zoneName,
                    onClose: {
                        viewModel.showSuccessAlert = false
                        // State is already set to .viewing in ViewModel
                    }
                )
            }
            
            // ✨ NEW: Delete confirmation alert overlay
            if viewModel.showDeleteAlert {
                DeleteConfirmationAlertView(
                    zoneName: viewModel.zoneName,
                    onCancel: { viewModel.showDeleteAlert = false },
                    onDelete: { viewModel.deleteZone() }
                )
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.loadPatientData()
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.currentState {
        case .noZone:
            NoZoneStateView(onAddLocation: {
                viewModel.startCreatingZone()
            })
            
        case .pickingLocation:
            PickLocationStateView(viewModel: viewModel)
            
        case .namingZone:
            NamingZoneStateView(viewModel: viewModel)
            
        case .viewing:
            ViewingZoneStateView(viewModel: viewModel)
        }
    }
}

// MARK: - Header

struct LocationHeader: View {
    let onBack: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 17))
                }
                .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text("Location")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Invisible spacer for centering
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.black)
    }
}

// MARK: - State 1: No Zone (Permission Cards + Add Button)

struct NoZoneStateView: View {
    let onAddLocation: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Permission cards with page indicator
            VStack(spacing: 16) {
                // Card 1: Device permissions
                PermissionCard(
                    icon: "location.fill",
                    title: "Device permissions",
                    description: "require to location permission to be \"on\" for the app to work"
                )
                
                // Page indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // "There is no location added" text
            Text("There is no location added")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .padding(.bottom, 20)
            
            // Add location button
            Button(action: onAddLocation) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Add location")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with checkmark
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                // Checkmark badge
                Circle()
                    .fill(Color.blue)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(x: 20, y: 20)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - State 2: Picking Location (Map + Slider)

struct PickLocationStateView: View {
    @ObservedObject var viewModel: SafeZoneViewModel
    
    var body: some View {
        ZStack {
            // Map
            Map(
                coordinateRegion: $viewModel.region,
                interactionModes: .all,
                showsUserLocation: false,
                annotationItems: [AnnotationItem(coordinate: viewModel.region.center)]
            ) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    // Patient pin with radius circle
                    ZStack {
                        // Radius circle
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: viewModel.circleSize, height: viewModel.circleSize)
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                        
                        // Patient pin
                        VStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 50, height: 50)
                                
                                Text(String(viewModel.patientName.prefix(1)).uppercased())
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            // Pin point
                            Triangle()
                                .fill(Color.blue)
                                .frame(width: 20, height: 12)
                                .offset(y: -6)
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // Bottom controls
            VStack {
                Spacer()
                
                BottomControlsView(viewModel: viewModel)
            }
            
            // Checkmark button (top right)
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        viewModel.confirmLocation()
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.blue)
                            )
                            .shadow(radius: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 80)
                }
                
                Spacer()
            }
        }
    }
}

struct BottomControlsView: View {
    @ObservedObject var viewModel: SafeZoneViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Patient label
            HStack {
                Text("Patient: \(viewModel.patientName)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            // Safe area title with slider
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Safe area")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.radius)) m Zone")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                // Radius slider
                Slider(value: $viewModel.radius, in: 50...2000, step: 50)
                    .accentColor(.blue)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .background(
            Color.black
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - State 3: Naming Zone (Name + Toggle + Save)

struct NamingZoneStateView: View {
    @ObservedObject var viewModel: SafeZoneViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Map preview (small)
            Map(coordinateRegion: .constant(viewModel.region),
                interactionModes: [],
                showsUserLocation: false)
                .frame(height: 200)
                .overlay(
                    // Address text overlay
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                            Text(viewModel.selectedAddress)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .padding(16)
                    }
                )
                .cornerRadius(16)
                .padding(16)
            
            Spacer()
            
            // Location Name input
            VStack(alignment: .leading, spacing: 12) {
                Text("Location Name")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                TextField("", text: $viewModel.zoneName)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(16)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            
            // Notification toggle
            HStack {
                Text("Notify me if \(viewModel.patientName) out of the safe side")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.notificationsEnabled)
                    .labelsHidden()
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            Spacer()
            
            // Save button
            Button(action: {
                viewModel.saveZone()
            }) {
                Text("Save")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.zoneName.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                    .cornerRadius(12)
            }
            .disabled(viewModel.zoneName.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - State 4: Viewing Zone (Saved Zone Display)

struct ViewingZoneStateView: View {
    @ObservedObject var viewModel: SafeZoneViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Map preview (large)
            Map(
                coordinateRegion: .constant(viewModel.region),
                interactionModes: [],
                showsUserLocation: false,
                annotationItems: [AnnotationItem(coordinate: viewModel.region.center)]
            ) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    // Patient pin with radius circle
                    ZStack {
                        // Radius circle
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: viewModel.circleSize, height: viewModel.circleSize)
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                        
                        // Patient pin
                        VStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 50, height: 50)
                                
                                Text(String(viewModel.patientName.prefix(1)).uppercased())
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            // Pin point
                            Triangle()
                                .fill(Color.blue)
                                .frame(width: 20, height: 12)
                                .offset(y: -6)
                        }
                    }
                }
            }
            .frame(height: 300)
            .cornerRadius(16)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Title and Action Buttons
            HStack {
                Text("\(viewModel.patientName) safe locations")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // ✨ NEW: Edit Button
                Button(action: {
                    viewModel.editZone()
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.gray.opacity(0.3)) // Gray background
                        .cornerRadius(8)
                }
                
                // ✨ NEW: Delete Button
                Button(action: {
                    viewModel.showDeleteAlert = true // Show confirmation alert
                }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.red) // Red background
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 24)
            
            // Zone card
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "house.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                
                // Name & Radius
                VStack(alignment: .leading) {
                    Text(viewModel.zoneName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("\(Int(viewModel.radius)) m Zone")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Toggle
                Toggle("", isOn: $viewModel.notificationsEnabled)
                    .labelsHidden()
                    .onChange(of: viewModel.notificationsEnabled) { _ in
                        viewModel.updateNotificationSettings()
                    }
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
}

// MARK: - Success Alert

struct SuccessAlertView: View {
    let zoneName: String
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Your new location \"\(zoneName)\" has been saved!")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 30)
                
                Button(action: onClose) {
                    Text("Close")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                        .padding(.bottom, 20)
                }
            }
            .background(Color(white: 0.15))
            .cornerRadius(16)
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Delete Confirmation Alert (✨ NEW)

struct DeleteConfirmationAlertView: View {
    let zoneName: String
    let onCancel: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Title and Message
                VStack(spacing: 5) {
                    Text("Delete Safe Zone?")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    Text("Are you sure you want to delete the safe zone **\"\(zoneName)\"**?")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 15)
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Delete Option (Destructive)
                Button(action: onDelete) {
                    Text("Delete")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.red) // Destructive styling
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Cancel Option
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.system(size: 17))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            .background(Color(white: 0.15))
            .cornerRadius(16)
            .padding(.horizontal, 40)
        }
    }
}


// MARK: - Helper Views

struct LoadingStateView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)
            Text("Loading...")
                .foregroundColor(.gray)
                .padding(.top, 20)
            Spacer()
        }
    }
}

struct NoPatientStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No Patient Found")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            Text("Please complete patient onboarding first")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

// MARK: - Map Annotation Item

struct AnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Triangle Shape (for pin point)

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    SafeZoneView()
}

