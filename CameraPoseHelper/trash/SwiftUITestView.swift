//
//  SwiftUITestView.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 24.05.2025.
//

import SwiftUI

struct SwiftUITestView: View {
    @State var show: Bool = false
    
    var body: some View {
        VStack {
            if show{
                Text("Hello, World!")
            }
            Button {
                withAnimation {
                    show.toggle()
                }
            } label: {
                Text("show")
            }

        }
    }
}

#Preview {
    SwiftUITestView()
}
