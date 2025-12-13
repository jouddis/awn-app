//
//  Pair done.swift
//  awaan test
//
//  Created by Maram on 22/06/1447 AH.
//

import SwiftUI

struct CheckmarkShape: Shape {
    var progress: CGFloat
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.2, y: rect.height * 0.5))
        path.addLine(to: CGPoint(x: rect.width * 0.45, y: rect.height * 0.75))
        path.addLine(to: CGPoint(x: rect.width * 0.8, y: rect.height * 0.3))
        
        return path.trimmedPath(from: 0, to: progress)
    }
}

struct Pairdone: View {
    
    let patientName: String
    
    @State private var checkmarkProgress: CGFloat = 0.0
    @State private var selectedPage = 0
    @State private var timer: Timer?
    
    // عشان نقفل الصفحات ونرجع للرئيسية (اختياري)
    @Environment(\.dismiss) var dismiss
    
    init(patientName: String) {
        self.patientName = patientName
        // تخصيص شكل النقاط حقت الصفحات
        UIPageControl.appearance().currentPageIndicatorTintColor = .white
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.5)
    }
    
    // دالة تشغيل الأنيميشن
    func startCheckmarkAnimation() {
        checkmarkProgress = 0.0
        
        withAnimation(.easeInOut(duration: 1.5)) {
            checkmarkProgress = 1.0
        }
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            checkmarkProgress = 0.0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 1.5)) {
                    checkmarkProgress = 1.0
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 1. Header (Static)
            VStack(spacing: 0) {
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
            
            // 2. Content
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
                
                TabView(selection: $selectedPage) {
                    
                    // --- Page 1 ---
                    VStack(spacing: 44) {
                        Text("connecting is done successfully !!")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        ZStack {
                            Image("Pair done")
                                .padding(.vertical, 33)
                            
                            // Checkmark with animation variable
                            CheckmarkShape(progress: checkmarkProgress)
                                .stroke(Color(hex: "B7B7B8"), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                                .frame(width: 77, height: 93)
                                .offset(y: -5)
                        }
                    }
                    .tag(0)
                    
                    // --- Page 2 ---
                    VStack(spacing: 44) {
                        Text("Make sure \(patientName) always wearing her Apple watch")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Image("hands")
                            .resizable().scaledToFit()
                            .frame(width: 360, height: 170)
                            .padding(.vertical, 33)
                    }
                    .tag(1)
                    
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 400)
                .padding(.top, 100)
                
                // Done Button
                if selectedPage == 1 {
                    Button(action: {
                        // هنا الكود لما يضغط Done
                        // عادة نوديه للصفحة الرئيسية للتطبيق
                        print("Done pressed - Go to Home")
                    }) {
                        Text("Done")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "6C7CD1").opacity(0.6))
                                    // عدلت الرقم هنا كان 22 خليته 0.22
                                    .shadow(color: Color.black.opacity(0.22), radius: 0.1, x: 0.7, y: 0.5)
                                    .shadow(color: Color.white.opacity(0.22), radius: 0.6, x: -0.5, y: -0.5)
                            )
                        
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                    .transition(.opacity)
                } else {
                    Spacer().frame(height: 60)
                }
                
                Spacer()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        
        .onAppear {
            startCheckmarkAnimation()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onChange(of: selectedPage) { newPage in
            if newPage == 0 {
                startCheckmarkAnimation()
            } else {
                timer?.invalidate()
            }
        }
    }
}

#Preview {
    Pairdone(patientName: "Norah")
}
