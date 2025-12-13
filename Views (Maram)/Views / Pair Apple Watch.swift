//
//   Pair Apple Watch.swift
//  awaan test
//
//  Created by Maram on 22/06/1447 AH.
//

import SwiftUI

struct PairAppleWatch: View {
    
    let patientName: String = "Norah"
    
    @State private var navigateToSuccess = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
                VStack {
                    ZStack{
                        RoundedRectangle(cornerRadius: 34)
                            .fill(Color(hex: "8B5CF6").opacity(0.20))
                            .frame(height: 390)
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
                    Text("Setting up \nProfile")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.7)
                        .padding(.top, 127)
                        .padding(.horizontal)
                
                VStack(spacing: 44) {
                    
                    Text("Configuring \(patientName)'s watch data...")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Image("Pair Apple Watch")
                        .padding(.vertical, 33)
                }
                .padding(.vertical, 13)
                .padding(.top, 168)
                
                Spacer()
            }
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                navigateToSuccess = true
            }
        }
        .navigationDestination(isPresented: $navigateToSuccess) {
            Pairdone(patientName: "Norah")
                .navigationBarBackButtonHidden(true)
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    NavigationStack {
        PairAppleWatch()
    }
}
