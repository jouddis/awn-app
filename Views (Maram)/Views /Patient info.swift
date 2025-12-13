//
//  Patient info.swift
//  awaan test
//
//  Created by Maram on 20/06/1447 AH.
//

import SwiftUI
struct Patientinfo: View {
    
    @StateObject private var viewModel = PatientInfoViewModel()
    
    var body: some View {
        NavigationView {
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
                        
                        // هذا عشان يصير فيه شوي قلاس ايفكت
                            .overlay(
                                RoundedRectangle(cornerRadius: 35)
                                    .stroke(Color.white.opacity(0.05), lineWidth: 4)
                                    .shadow(color: Color.white.opacity(0.12), radius: 2, x: 22, y: 33)
                                    .shadow(color: Color.white.opacity(0.12), radius: 0.6, x: 0.5, y: 0)
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
                    Text("Let's make caring easier together")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.top, 100)
                    
                    //عشان ما يطلع الكلام لفوق (تثبيت المساحة)
                    Color.clear
                        .frame(height: 100)
                    
                    
                    //Patient Name sec
                    VStack(alignment: .leading, spacing: 12) {
                        
                        Text("Patient Name")
                            .foregroundColor(Color(hex: "6C7CD1"))
                            .font(.system(size: 18, weight: .medium))
                        
                        ZStack(alignment: .leading) {
                            // استخدام viewModel.name
                            if viewModel.name.isEmpty {
                                Text("Type patient name here")
                                    .foregroundColor(.gray)
                            }
                            TextField("", text: $viewModel.name)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.35))
                                .shadow(color: Color.black.opacity(22), radius: 0.1, x: 0.7, y: 0.5)
                                .shadow(color: Color.white.opacity(22), radius: 0.6, x: -0.5, y: -0.5)
                        )
                        
                        
                        VStack(alignment: .leading,spacing: 20){
                            Text("Your relation with Patient")
                                .foregroundColor(Color(hex: "6C7CD1"))
                                .font(.system(size: 18, weight: .medium))
                                .padding(.top, 18)
                            
                            // الأزرار
                            HStack(spacing: 22) {
                                ForEach(["Son","Daughter","Other"], id: \.self) { title in
                                    
                                    Button(action: {
                                        withAnimation {
                                            // استخدام viewModel.selectedRelation
                                            viewModel.selectedRelation = title
                                        }
                                    }) {
                                        Text(title)
                                            .foregroundColor(.white)
                                            .font(.system(size: 17, weight: .medium))
                                            .padding(.vertical, 15)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                RoundedRectangle(cornerRadius: 34)
                                                    .fill(
                                                        viewModel.selectedRelation == title
                                                        ? Color(hex: "6C7CD1").opacity(0.6)
                                                        : Color.black.opacity(0.35)
                                                    )
                                                    .shadow(color: Color.black.opacity(22), radius: 0.1, x: 0.7, y: 0.5)
                                                    .shadow(color: Color.white.opacity(22), radius: 0.6, x: -0.5, y: -0.5)
                                            )
                                    }
                                }
                            }
                            
                            if viewModel.selectedRelation == "Other" {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Please specify")
                                        .foregroundColor(Color(hex: "6C7CD1"))
                                        .font(.system(size: 18, weight: .medium))
                                        .padding(.top, 5)
                                    
                                    ZStack(alignment: .leading) {
                                        if viewModel.otherRelationDetails.isEmpty {
                                            Text("Type relation here")
                                                .foregroundColor(.gray)
                                        }
                                        // استخدام viewModel.otherRelationDetails
                                        TextField("", text: $viewModel.otherRelationDetails)
                                            .foregroundColor(.white)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.black.opacity(0.35))
                                            .shadow(color: Color.black.opacity(22), radius: 0.1, x: 0.7, y: 0.5)
                                            .shadow(color: Color.white.opacity(22), radius: 0.6, x: -0.5, y: -0.5)
                                    )
                                }
                            }
                            
                        }
                    }
                    .padding()
                    //عشان يرفع كل شيء لفوق شوي
                    .padding(.top, -36)
                    
                    Spacer()
                    
                    // next
//                    Button(action: {
//                        
//                        // استدعاء دالة الإرسال من الـ ViewModel
//                        viewModel.submitData()
//                    }) {
                    NavigationLink(destination: FamilySetup(patientName: viewModel.name)) {
                        HStack(spacing: 8) {
                            
                            Text("Next")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .bold))
                        }
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                            // استخدام viewModel.isFormValid
                                .fill(viewModel.isFormValid ? Color(hex: "6C7CD1").opacity(0.6) : Color.black.opacity(0.35))
                                .shadow(color: Color.black.opacity(22), radius: 0.1, x: 0.7, y: 0.5)
                                .shadow(color: Color.white.opacity(22), radius: 0.6, x: -0.5, y: -0.5)
                        )
                    }
                    .disabled(!viewModel.isFormValid)
                    .animation(.easeInOut, value: viewModel.isFormValid)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 33)
                }
            }
            .transition(.opacity)
        }
    }
}

#Preview {
    Patientinfo()
}



