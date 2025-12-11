////
////  LoginScreen.swift
////  awaan test
////
////  Created by Maram on 19/06/1447 AH.
////
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct LoginScreen: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            // الفريم البنفسجي اللي ورا
            VStack {
                ZStack{
                    RoundedRectangle(cornerRadius: 34)
                        .fill(Color(hex: "8B5CF6").opacity(0.20))
                    
                    
                        .frame(height: 380)
                        .offset(x: 0, y: -122)


                        .shadow(color: Color.black.opacity(22), radius: 0.1, x: 0, y: -0.4)
                        .shadow(color: Color.white.opacity(22), radius: 0.12, x: -0.5, y: -0.12)
                    
                    // هذا عشان يصير فيه شوي قلاس ايفكت
                        .overlay(
                            RoundedRectangle(cornerRadius: 35)
                                .stroke(Color.white.opacity(0.05), lineWidth: 4)
                                .shadow(color: Color.white.opacity(0.12), radius: 2, x: 22, y: 33)
                                .shadow(color: Color.white.opacity(12), radius: 0.6, x: 0.5, y: 0)
                              .offset(x: 0, y: -122)
     
                        )
                    // الدائره البنفسجيه الاولى
                    Circle()
                        .fill(Color(hex: "6C7CD1").opacity(0.37))
                        .frame(width: 400, height: 460)
                        .offset(x: -300, y: -30)
                        .rotationEffect(.degrees(50))
                    // الدائره البنفسجيه الثانيه
                    Circle()
                        .fill(Color(hex: "8595E9").opacity(0.62))
                        .frame(width: 270, height: 400)
                        .offset(x: -366, y: -22)
                        .rotationEffect(.degrees(50))
                }
                
                    Spacer()
                }

            
            
            VStack(spacing: 20) {
                // الكلام اللي داخل الفريم
                VStack(spacing: 15) {
                    Text("Sign in to your\nAccount")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("To stay updated with your patient’s safety and medications")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                       // .padding(.horizontal, 40)
                        .frame(width: 280)
                }
                .padding(.top, 100)
                
                Spacer()
                
                VStack(spacing: 20) {
                    Text("Please sign in with Apple")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                    
                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Image(systemName: "applelogo")
                                .foregroundColor(.white)
                                .font(.system(size: 18))

                            Text("Sign In With Apple")
                                .foregroundColor(.white)
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 40)
                                .fill(Color.black.opacity(0.35))

                                    .shadow(color: Color.black.opacity(22), radius: 0.1, x: 0.7, y: 0.5)
                                    .shadow(color: Color.white.opacity(22), radius: 0.6, x: -0.5, y: -0.5)
                        )
                        
                        
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                    }
                    .padding(.horizontal, 30)
                }
                
                Spacer()
                
                Button("Skip for now") { }
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
            }
        }
    }
}

#Preview {
    LoginScreen()
}
