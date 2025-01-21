//
//  SettingsView.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 30.10.2024.
//

import SwiftUI
import BoilerCore

struct OverCamSettingsView: View {
    
    @State var showTerms : Bool = false
    @State var showPrivacy : Bool = false
    @State var showEULA : Bool = false
    @State private var showRating = false

    
    var body: some View {
        List {
            
//            if FastApp.subscriptions.isSubscribed == false {
//                Button {
//                    FastApp.subscriptions.showPaywallScreen()
//                } label: {
//                    Text("Unlock Premium")
//                        .foregroundStyle(Color.accentColor)
//                    
//                }
//            }
            
            Button {
                showTerms.toggle()
            } label: {
                Text("Terms of Use")
                    .foregroundStyle(Color.accentColor)
                    .underline()
            }
            
            
            
            Button {
                showPrivacy.toggle()
            } label: {
                Text("Privacy Policy")
                    .foregroundStyle(Color.accentColor)
                    .underline()
            }
            
            Button {
                showEULA.toggle()
            } label: {
                Text("EULA")
                    .foregroundStyle(Color.accentColor)
                    .underline()
            }
            
            Link("Contact Us", destination: URL(string: "https://t.me/imbalanceFighter")!)
            
//            Button {
//                FastApp.onboarding.show()
//            } label: {
//                Text("How to Use")
//                    .foregroundStyle(Color.accentColor)
//            }
            
            Text("Show Rating")
                .onTapGesture {
                    self.showRating = true
                }
        }.withRatingFeature(showRating: self.$showRating)
    }
}

//#Preview {
//    SettingsView()
//}
