//
//  CameraPermission.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 26.05.2025.
//

import SwiftUI
import CoreMotion


struct CameraPermission: View {
    
    @Environment(\.openURL) private var openURL
    @StateObject private var motion = MotionManager()
    @EnvironmentObject var cameraManager: NewCameraManager

    @State private var elapsed: Float = 1
    @State private var counter: Float = 1
    
    
    var body: some View {
        if cameraManager.permissionGranted == false {
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
                    
                    Text("Camera Permission is required.")
                        .font(.doto(.black, size: 45))
                        .offset(x: motion.x * 10, y: motion.y * 10)
                        .foregroundStyle(
                            LinearGradient(colors: [Color.introOne,Color.introTwo], startPoint: .leading, endPoint: .trailing)
                        )
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Hey, this is the main feature of the app! We need your permission to use the camera. Nothing will work without your permission.")
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(.dirtyWhite)
                        
                    }.offset(x: motion.x * 5, y: motion.y * 5)
                    
                    Button {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            openURL(settingsURL)
                        }
                    } label: {
                        HStack {
                            Text("Open Settings")
                        }
                        .font(.subheadline)
                        .lineLimit(1)
                        .foregroundStyle(.dirtyWhite)
                        .padding(.vertical,10)
                        .padding(.horizontal,13)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    
                }
                .foregroundStyle(.ultraThickMaterial)
                .padding(30)
                
            }
            .background(.black)
            .onAppear {
                cameraManager.getCurrentPermissions()
            }
        }
    }
}
