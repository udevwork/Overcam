//
//  LastCapturedImage.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 25.05.2025.
//

import SwiftUI

struct LastCapturedImage: View {
    
    @EnvironmentObject var cameraManager: NewCameraManager
    
    var body: some View {
        if let img = cameraManager.lastCapturedImage {
            
            Button(action: {
                UIApplication.shared.open(URL(string:"photos-redirect://")!)
            }) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
                    .frame(width: 40, height: 40, alignment: .center)
                
            }
            .transition(.blurReplace)
            
        }
    }
}

#Preview {
    LastCapturedImage()
}
