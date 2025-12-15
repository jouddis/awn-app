//
//  SplashScreenView.swift
//  awn app
//
//  Created by saja on 24/06/1447 AH.
//
import SwiftUI

struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var textOffset: CGFloat = 20
    @State private var textOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 6) {

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 400, height: 400)
                    .shadow(color: Color.gray.opacity(0.2), radius: 12, x: 0, y: 8)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .onAppear {
                        withAnimation(.easeIn(duration: 0.8)) {
                            logoScale = 1.0
                            logoOpacity = 1.0
                        }
                    }

                // كلمة "عون"
                Image("fontaoun")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 50)
                    .offset(y: -80)
                // ⬅️ هذا يرفع كلمة عون

                // عبارة "نرافقك في رعاية من تحب"
                Image("slogan")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
                    .offset(y: -60)    // ⬅️ هذا يرفع العبارة
            }

        }
    }
}

#Preview {
    SplashScreenView()
}
