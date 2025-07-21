//
//  FocusLabel.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 21.07.2025.
//

import SwiftUI

struct FocusLabel: View {
    
    @EnvironmentObject var cameraManager: NewCameraManager
    @State private var zoomLabelOpacity: CGFloat = 0.0

    
    var body: some View {
  
            HStack {
                Text("focus")
                Image(systemName: cameraManager.focusLocked ? "lock" : "lock.open")
            }
            .font(.footnote)
            .padding(.vertical, 10)
            .padding(.horizontal, 11)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20.0))
            .foregroundStyle(.secondary)
            .onTapGesture {
                if cameraManager.focusLocked == false {
                    return
                }
                withAnimation {
                    cameraManager.unlockFocus()
                }
            }
            .opacity( cameraManager.focusLocked ? 1 : zoomLabelOpacity)
            .onChange(of: cameraManager.focusLocked) {
                zoomLabelOpacity = 1
                withAnimation(.easeInOut.delay(0.5)) {
                    zoomLabelOpacity = 0
                    
                }
         
            }

    }
}
