//
//  MotionManager.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 24.05.2025.
//


import SwiftUI
import CoreMotion

class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    
    // Опорная (нулевая) ориентация
    private var referenceAttitude: CMAttitude?
    // Последние выданные значения, для развёртки угла
    private var lastRoll: Double = 0
    private var lastPitch: Double = 0
    
    @Published var x: Double = 0.0  // roll
    @Published var y: Double = 0.0  // pitch
    
    init() {
        startMotionUpdates()
    }
    
    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        // Можно выбрать нужный referenceFrame, по умолчанию .xArbitraryZVertical
        motionManager.startDeviceMotionUpdates(
            using: .xArbitraryZVertical,
            to: .main
        ) { [weak self] motion, error in
            guard let self = self,
                  let motion = motion,
                  error == nil else { return }
            
            // Если это первая «рабочая» итерация — запоминаем нулевую ориентацию
            if self.referenceAttitude == nil {
                self.referenceAttitude = motion.attitude.copy() as? CMAttitude
                // на старте выдаём 0,0
                DispatchQueue.main.async {
                    self.x = 0
                    self.y = 0
                }
                return
            }
            
            // Создаём копию и приводим к относительной системе
            let relAtt = motion.attitude.copy() as! CMAttitude
            relAtt.multiply(byInverseOf: self.referenceAttitude!)
            
            var roll  = relAtt.roll   // от –π до π
            var pitch = relAtt.pitch  // от –π/2 до π/2
            
            // «Развёртка» угла, чтобы избежать перескоков через границу
            let dRoll  = roll  - self.lastRoll
            let dPitch = pitch - self.lastPitch
            
            if dRoll >  Double.pi  { roll  -= 2 * Double.pi }
            if dRoll < -Double.pi  { roll  += 2 * Double.pi }
            
            if dPitch >  Double.pi { pitch -= 2 * Double.pi }
            if dPitch < -Double.pi { pitch += 2 * Double.pi }
            
            // Обновляем published свойства
            DispatchQueue.main.async {
                self.x = roll
                self.y = pitch
            }
            
            // Запоминаем для следующей итерации
            self.lastRoll  = roll
            self.lastPitch = pitch
        }
        
        // Интервал 60 Гц
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}


struct SettingsView: View {
    
    @StateObject private var motion = MotionManager()
    @State private var elapsed: Float = 1
    @State private var counter: Float = 1

    var items: [TextEmoji] = [
        .init(text: "Reate us!"),
        .init(text: "Web"),
        .init(text: "Telegram"),
        .init(text: "Email"),
        .init(text: "Insta"),
        .init(text: "More apps"),
        .init(text: "Policy"),
        .init(text: "Terms"),
        .init(text: "Share")
    ]

    var body: some View {
        ZStack {
            Image("img")
                .resizable()
                .scaleEffect(1.2)
                .ignoresSafeArea()
                .colorEffect(
                    ShaderLibrary.oilSlick(.float(elapsed), .float(counter))
                )
                .distortionEffect(
                    ShaderLibrary.wave( .float(Float(motion.x * 10)), .float(Float(motion.y * 10))  ),
                    maxSampleOffset: .zero
                )
                .onAppear {
                    Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
                        elapsed += 0.16 // Каждые ~16мс, чтобы шло как 60 fps
                    }
                }

            VStack(alignment: .leading, spacing: 20) {
                Text("Become a part of us.")
                    .font(.system(size: 30, weight: .black, design: .serif))
                    .offset(x: motion.x * 10, y: motion.y * 10)
                    .foregroundStyle(
                        LinearGradient(colors: [Color.introOne,Color.introTwo], startPoint: .leading, endPoint: .trailing)
                    )

                VStack(alignment: .leading, spacing: 0) {
                    Text("Our goal is to inspire you to create breathtaking, artistic photographs, and we hope this tool will help you craft original works and learn composition from professionals. Join our team—we’re open to dialogue and committed to continuous improvement.")
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundStyle(.dirtyWhite)
                    HStack {
                        Spacer()
                        Text("- 01lab")
                            .multilineTextAlignment(.trailing).bold()
                            .foregroundStyle(.dirtyWhite.opacity(0.5))
                    }
                }  .offset(x: motion.x * 5, y: motion.y * 5)
                
                Spacer()
                
                FlowLayout(items: items, spacing: 6) { i in
                    HStack {
                        Text(i.text).bold()
                    }
                    .font(.subheadline)
                    .lineLimit(1)
                    .foregroundStyle(.dirtyWhite)
                    .padding(.vertical,10)
                    .padding(.horizontal,13)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                }
                
      
                HStack {
                    Image("logo")
                        .resizable()
                        .frame(width: 30, height: 30)
                    VStack(alignment:.leading) {
                        Text("Created by".uppercased()).foregroundStyle(.dirtyWhite.opacity(0.5))
                        Text("01lab")  .foregroundStyle(.dirtyWhite)
                    }
                }
            }
            .foregroundStyle(.ultraThickMaterial)
            .padding(30)
           
        }.background(.black)
    }
}
