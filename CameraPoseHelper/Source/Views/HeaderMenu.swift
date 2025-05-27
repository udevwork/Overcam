//
//  HeaderMenu.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 25.05.2025.
//

import SwiftUI


struct HeaderMenu : View {
    
    @EnvironmentObject var cameraManager: NewCameraManager

    var topIconsSize: CGFloat = 18

    
    var body: some View {
        HStack(spacing: 20) {
            Button {
                cameraManager.flash.toggle()
                cameraManager.setTorch(active: cameraManager.flash)
                hapticLight()
            } label: {
                
                Image(systemName: cameraManager.flash ? "flashlight.on.circle.fill" : "flashlight.off.circle")
                    .resizable()
                    .frame(width: topIconsSize, height: topIconsSize)
                    .fontDesign(.rounded)
            }
            
            
            Button {
                withAnimation {
                    cameraManager.grid.toggle()
                }
                hapticLight()
            } label: {
                if cameraManager.grid {
                    Image(systemName: "grid")
                        .resizable()
                        .frame(width: topIconsSize, height: topIconsSize)
                } else {
                    Image(systemName: "grid")
                        .resizable()
                        .frame(width: topIconsSize, height: topIconsSize)
                        .opacity(0.5)
                    
                }
            }
            
            Button {
                cameraManager.front.toggle()
                if cameraManager.front {
                    cameraManager.switchToFrontCamera()
                } else {
                    cameraManager.switchToBackCamera()
                }
                hapticLight()
            } label: {
                if cameraManager.front {
                    Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: topIconsSize, height: topIconsSize)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: topIconsSize, height: topIconsSize)
                }
            }
            
            ForEach(cameraManager.availableDevices, id: \.self) { device in
                
                Button(action: {
                    cameraManager.front = false
                    hapticLight()
                    cameraManager.reswitchCamera(to: device)
                }) {
                    Text(String(format: "%.1fx", device.nominalZoom)).font(.system(.footnote, design: .monospaced, weight: .bold))
                }
                .disabled(device == cameraManager.currentdevice)
                .opacity(device == cameraManager.currentdevice ? 0.5 : 1)
                
            }
            
            Spacer()
            
            
            NavigationLink {
                SettingsView()
            } label: {
                Image(systemName: "gearshape.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: topIconsSize, height: topIconsSize)
            }
            
        }
        .foregroundStyle(.accent)
        .padding()
        .transition(.blurReplace)
    }
}
