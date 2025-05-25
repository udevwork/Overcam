//
//  ZoomLabel.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 25.05.2025.
//

import SwiftUI

struct ZoomLabel: View {
    
    @EnvironmentObject var cameraManager: NewCameraManager
    @State private var zoomLabelOpacity: CGFloat = 0.0
    
    var body: some View {
        Text(String(format: "%.2f", cameraManager.zoom))
            .bold()
            .font(.footnote)
            .fontDesign(.monospaced)
            .opacity(zoomLabelOpacity)
            .onChange(of: cameraManager.zoom) {
                zoomLabelOpacity = 1
                withAnimation {
                    zoomLabelOpacity = 0
                }
            }
    }
}
