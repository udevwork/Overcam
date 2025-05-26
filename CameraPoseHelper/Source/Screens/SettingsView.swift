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
    
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) var requestReview
    @Environment(\.dismiss) var dismiss
    @StateObject private var motion = MotionManager()
    @State private var elapsed: Float = 1
    @State private var counter: Float = 1
    
    @State private var showPrivacy: Bool = false
    @State private var showTerms: Bool = false
    @State private var isSharePresented: Bool = false
    
    var items: [TextEmoji] = [
        .init(text: "Reate us!"),
        .init(text: "Web"),
        .init(text: "Telegram"),
        .init(text: "Email"),
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
                
                Button {
                    dismiss()
                } label: {
                    Text("<")
                        .font(.doto(.black, size: 45))
                        .foregroundStyle(
                            LinearGradient(colors: [Color.introOne,Color.introTwo], startPoint: .leading, endPoint: .trailing)
                        )
                }
                
                
                Text("Become a part of us.")
                    .font(.doto(.black, size: 45))
                    .offset(x: motion.x * 10, y: motion.y * 10)
                    .foregroundStyle(
                        LinearGradient(colors: [Color.introOne,Color.introTwo], startPoint: .leading, endPoint: .trailing)
                    )
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Our goal is to inspire you to create breathtaking, artistic photographs, and we hope this tool will help you craft original works and learn composition from professionals. Join our team—we’re open to dialogue and committed to continuous improvement.")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.dirtyWhite)
                    
                }.offset(x: motion.x * 5, y: motion.y * 5)
                
                Spacer()
                
                FlowLayout(items: items, spacing: 6) { i in
                    Button {
                        switch i.text {
                            case "Reate us!": requestReview()
                            case "Web": openURL(WEBSITE)
                            case "Telegram": openURL(TG_SUPPORT)
                            case "Email": openMail()
                            case "More apps": openURL(MORE_APPS)
                            case "Policy": showPrivacy.toggle()
                            case "Terms": showTerms.toggle()
                            case "Share": isSharePresented.toggle()
                            default:
                                return
                        }
                    } label: {
                        HStack {
                            Text(i.text)
                        }
                        .font(.subheadline)
                        .lineLimit(1)
                        .foregroundStyle(.dirtyWhite)
                        .padding(.vertical,10)
                        .padding(.horizontal,13)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                    }
                    
                    
                }
                
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Created by".uppercased()).foregroundStyle(.dirtyWhite.opacity(0.5))
                        Text("01lab") .foregroundStyle(.dirtyWhite)
                    }.font(.footnote)
                }
            }
            .foregroundStyle(.ultraThickMaterial)
            .padding(30)
            
        }
        .background(.black)
        .navigationBarBackButtonHidden()
        .sheet(isPresented: $showTerms) { WebViewScreen(url: TERMS_CONDITIONS_LINK) }
        .sheet(isPresented: $showPrivacy) { WebViewScreen(url: PRIVACY_POLICY_LINK) }
        .sheet(isPresented: $isSharePresented) { ShareView( items: [APPSTORE_URL] ) }

    }
    
    func openMail() {
        
        let subject = "OverCam app"
        let body = "Hello!\n"
        let emailTo = EMAIL_SUPPORT
        
        if let url = URL(string: "mailto:\(emailTo)?subject=\(subject.fixToBrowserString())&body=\(body.fixToBrowserString())"),
           UIApplication.shared.canOpenURL(url)
        {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

}

extension String {
    func fixToBrowserString() -> String {
        self.replacingOccurrences(of: ";", with: "%3B")
            .replacingOccurrences(of: "\n", with: "%0D%0A")
            .replacingOccurrences(of: " ", with: "+")
            .replacingOccurrences(of: "!", with: "%21")
            .replacingOccurrences(of: "\"", with: "%22")
            .replacingOccurrences(of: "\\", with: "%5C")
            .replacingOccurrences(of: "/", with: "%2F")
            .replacingOccurrences(of: "‘", with: "%91")
            .replacingOccurrences(of: ",", with: "%2C")
            //more symbols fixes here: https://mykindred.com/htmlspecialchars.php
    }
}
