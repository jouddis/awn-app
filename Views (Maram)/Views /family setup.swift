//
//  family setup.swift
//  awaan test
//
//  Created by Maram on 21/06/1447 AH.

import SwiftUI
struct FamilySetup: View {
    let patientName: String
    @State private var showSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    ZStack{
                        RoundedRectangle(cornerRadius: 34)
                            .fill(Color(hex: "8B5CF6").opacity(0.20))
                            .frame(height: 330)
                            .offset(x: 0, y: -122)
                            .shadow(color: Color.black.opacity(0.22), radius: 0.1, x: 0, y: -0.4)
                            .shadow(color: Color.white.opacity(0.22), radius: 0.12, x: -0.5, y: -0.12)
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
                
                VStack(spacing: 12) {
                    Text("Connect the Apple\nWatch")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.7)
                        .padding(.top, 90)
                        .padding(.horizontal)
                    
                    VStack(spacing: 5) {
                        (
                            Text("Connect \(patientName)’s Apple Watch to track her location")
                            + Text(" via family set up")
                                .foregroundColor(Color(hex: "8595E9"))
                                .fontWeight(.bold)
                            + Text(" to continue benefiting from Awn")
                        )
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        
                        Image("Apple Watch location")
                            .padding(.vertical, 33)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 120)
                    
                    Spacer()
                    
                    VStack(spacing: 15) {
                        
                        NavigationLink(destination: PairAppleWatch().navigationBarBackButtonHidden(true)) {
                            Text("I did family setup")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .bold))
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "6C7CD1").opacity(0.6))
                                        .shadow(color: Color.black.opacity(0.22), radius: 0.1, x: 0.7, y: 0.5)
                                        .shadow(color: Color.white.opacity(0.22), radius: 0.6, x: -0.5, y: -0.5)
                                )
                        }
                        .padding(.horizontal, 30)
                        
                        Button(action: {
                        }) {
                            Text("I’ll do this later")
                                .foregroundColor(Color.gray)
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarBackButtonHidden(true)
            
            .sheet(isPresented: $showSheet) {
                ZStack {
                    Color.black.ignoresSafeArea()
                    RoundedRectangle(cornerRadius: 35)
                        .fill(Color(hex: "1A1A1A"))
                        .shadow(color: Color.white.opacity(0.05), radius: 6, x: 0, y: -2)
                        .shadow(color: Color.black.opacity(0.8), radius: 10, x: 5, y: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 35)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .ignoresSafeArea()
                    
                    VStack(spacing: 25) {
                        
                        Image("Family")
                        
                        Text("Family Sharing")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 0) {
                            Text("Enable Family Sharing from the settings on your device to track the patient’s location. To learn more, please ")
                                .foregroundColor(.gray)
                            +
                            Text("visit link")
                                .foregroundColor(.blue)
                                .underline()
                        }
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .onTapGesture {
                            if let url = URL(string: "https://support.apple.com/en-sa/108380") {
                                UIApplication.shared.open(url)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 33) {
                            
                            HStack(spacing: 12) {
                                Image(systemName: "gearshape.fill")
                                    .font(.title3)
                                    .foregroundColor(Color(hex: "6C7CD1"))
                                Text("1. Open your iPhone Settings")
                                    .foregroundColor(.white)
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(Color(hex: "6C7CD1"))
                                Text("2. Tap on your Apple ID")
                                    .foregroundColor(.white)
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "person.2.badge.plus.fill")
                                    .font(.title3)
                                    .foregroundColor(Color(hex: "6C7CD1"))
                                Text("3. Then add Family Members")
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 30)
                        
                        Spacer()
                        
                        // زر الذهاب للإعدادات
                        Button(action: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                if UIApplication.shared.canOpenURL(url) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            showSheet = false
                        }) {
                            Text("Go to Settings")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(hex: "6C7CD1"))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            
                        }
                        .padding(.horizontal, 66)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 57)
                }
                .presentationDetents([.height(610)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(35)
                .presentationBackground(.clear)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showSheet = true
                }
            }
        }
    }
}

#Preview {
    FamilySetup(patientName: "Norah")
}
