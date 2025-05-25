//
//  CaptureButton.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 25.05.2025.
//

import SwiftUI

struct CaptureButton: View {
    
    @Binding var cameraViewAvalable: Bool?
    var onPress: ()->()
    
    var body: some View {
        Button(action: {
            haptic()
            onPress()
        }) {
            ZStack {
                Circle()
                    .frame(width: 40, height: 40, alignment: .center)
                    .foregroundStyle(.accent)
                if cameraViewAvalable == nil {
                    ProgressView()
                }
            }
        }
        .disabled(!(cameraViewAvalable ?? false))
        .opacity((cameraViewAvalable ?? false) ? 1.0 : 0.5)
    }
}

