//
//  ReferenceImageOpacitySlider.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 25.05.2025.
//

import SwiftUI
import CompactSlider

struct ReferenceImageOpacitySlider: View {
    
    @EnvironmentObject var cameraManager: NewCameraManager
    
    var body: some View {
        if cameraManager.referenceImage != nil {
            CompactSlider(value: $cameraManager.referenceAlpha,
                          in: 0.1...0.9,
                          step: 0.025,
                          direction: .center,
                          handleVisibility: .hovering(width: 1.0),
                          scaleVisibility: .hovering,
                          minHeight: 30,
                          enableDragGestureDelayForiOS: false
            ) {
                
                Spacer()
                Text(String(format: "%.2f", cameraManager.referenceAlpha)).font(.system(.footnote, design: .monospaced, weight: .bold))
            }
            .compactSliderStyle(.single)
        }
    }
}
