//
//  SlidersStack.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 25.05.2025.
//

import SwiftUI
import CompactSlider

struct SlidersStack: View {
    
    @EnvironmentObject var cameraManager: NewCameraManager
    
    var body: some View {
        VStack(spacing: 3) {
            
            CompactSlider(value: $cameraManager.iso,
                          in: 50...1600,
                          step: 50,
                          direction: .center,
                          handleVisibility: .hovering(width: 1.0),
                          scaleVisibility: .hovering,
                          minHeight: 30,
                          enableDragGestureDelayForiOS: false
            ) {
                Text("ISO").font(.system(.footnote, design: .monospaced, weight: .bold))
                Spacer()
                
                Text(String(format: "%.2f", cameraManager.iso)).font(.system(.footnote, design: .monospaced, weight: .bold))
            }
            .compactSliderStyle(.top)
            .onChange(of: cameraManager.iso, {
                cameraManager.setCustomExposure()
            })
            .transition(.blurReplace)
            
            CompactSlider(value: $cameraManager.expBias,
                          in: cameraManager.camExpRange.0.asSeconds...cameraManager.camExpRange.1.asSeconds/100,
                          step: 0.0005,
                          direction: .center,
                          handleVisibility: .hovering(width: 1.0),
                          scaleVisibility: .hovering,
                          minHeight: 30,
                          enableDragGestureDelayForiOS: false
            ) {
                Text("SS").font(.system(.footnote, design: .monospaced, weight: .bold))
                Spacer()
                Text(cameraManager.expBias.asExposureString).font(.system(.footnote, design: .monospaced, weight: .bold))
            }
            .compactSliderStyle(.middle)
            .onChange(of: cameraManager.expBias, {
                cameraManager.setCustomExposure()
            })
            .transition(.blurReplace)
            
            CompactSlider(value: $cameraManager.referenceAlpha,
                          in: 0.1...0.9,
                          step: 0.025,
                          direction: .center,
                          handleVisibility: .hovering(width: 1.0),
                          scaleVisibility: .hovering,
                          minHeight: 30,
                          enableDragGestureDelayForiOS: false
            ) {
                Text("Ref opacity").font(.system(.footnote, design: .monospaced, weight: .bold))
                Spacer()
                Text(String(format: "%.2f", cameraManager.referenceAlpha)).font(.system(.footnote, design: .monospaced, weight: .bold))
            }
            .compactSliderStyle(.bottom)
            .opacity(cameraManager.referenceImage == nil ? 0.5 : 1)
            .blur(radius: cameraManager.referenceImage == nil ? 1 : 0)
            .disabled(cameraManager.referenceImage == nil)
            
        }
        .padding(.bottom, 6)
        .padding(.trailing, 6)
        
    }
}

