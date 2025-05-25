//
//  TutorView.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 30.10.2024.
//

import SwiftUI


struct TutorialArrowView: View {
    
    @Binding var complete: Bool
    
    @State private var offset: CGFloat = 5  // начальное смещение
    @State private var opasity: CGFloat = 0.5  // начальное смещение

    var body: some View {
        if complete == false {
            VStack {
                Image("arrow_up")  // замените на имя вашего изображения
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                Text("SWIPE")
                    .bold()
                    .foregroundStyle(.accent)
                
            }
            .shadow(radius: 4)
            .offset(y: offset)
            .opacity(opasity)
            
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true)
            )
            .onAppear {
                offset = -5  // конечное смещение для бесконечной анимации
                opasity = 1  // конечное смещение для бесконечной анимации
            }
            .transition(.blurReplace)
        }
    }
}
