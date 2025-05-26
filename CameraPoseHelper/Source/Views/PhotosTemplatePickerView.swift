//
//  PhotosTemplatePickerView.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 26.08.2024.
//

import SwiftUI
import PhotosUI


struct PhotosTemplatePickerView: View {
    
    @StateObject var subscriptions = SubscriptionManager.shared

    @State private var selectedIndex: Int = -1
    private var photoPrefix: String = "photo-"
    @State private var photoItem: PhotosPickerItem? = nil
    
    @State private var showPrivacy: Bool = false
    @State private var showTerms: Bool = false
    
    
    // public
    @Binding var selectedImage: CGImage?
    @Binding var showPaywall: Bool
    let namespace: Namespace.ID
    
    init(
        selectedImage: Binding<CGImage?>,
        showPaywall: Binding<Bool>,
        namespace: Namespace.ID
    ) {
        self._selectedImage = selectedImage
        self._showPaywall = showPaywall
        self.namespace = namespace
    }
    
    var body: some View {
        VStack {
            Spacer().frame(width: 0, height: 5)
            ScrollView(.horizontal) {
                HStack(alignment: .center, spacing: 10) {
                    
                    Rectangle()
                        .frame(width: 16, height: 40)
                        .foregroundStyle(.clear)
                    
                    
                    if subscriptions.isSubscribed {
                        PhotosPicker(selection: $photoItem) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .frame(width: 40, height: 40)
                                    .foregroundStyle(.dirtyWhite)
                                
                                Image(systemName: "plus")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(.accent)
                            }
                        }.onChange(of: photoItem) {
                            Task {
                                if let data = try? await photoItem?.loadTransferable(type: Data.self),
                                   let img = UIImage(data: data) {
                                    selectedImage = img.cgImage
                                } else {
                                    print("Failed")
                                }
                            }
                        }
                    } else {
                        Button {
                            withAnimation(.easeInOut) {
                                showPaywall.toggle()
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: showPaywall ? 40 : 16, style: .continuous)
                                    .matchedGeometryEffect(id: "rectangle", in: namespace, isSource: !showPaywall)
                                    .frame(width: 40, height: 40)
                                    .foregroundStyle(.dirtyWhite)
                                
                                
                                Image(systemName: "plus")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(.accent)
                                    .rotationEffect( showPaywall ? .degrees(45) : .degrees(0))
                                
                            }
                            .frame(width: 40, height: 40)
                        }
                    }
                    
                    if showPaywall == false {
                        ForEach((0..<25)) { i in
                            VStack {
                                Image("\(photoPrefix)\(i)")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .scrollTransition(
                                        .interactive(timingCurve: .easeInOut),
                                        axis: .horizontal
                                    ) { content, phase in
                                        content
                                            .scaleEffect(phase.isIdentity ? 1 : 0.6 + 0.4 * (1 - abs(phase.value)))
                                            .blur(radius: phase.isIdentity ? 0 : 8 * abs(phase.value))
                                            .opacity(phase.isIdentity ? 1 : 0.7)
                                    }
                                    .onTapGesture {
                                        if showPaywall == false {
                                            if i != selectedIndex {
                                                withAnimation {
                                                    selectedIndex = i
                                                    if let uiImage = UIImage(named: "\(photoPrefix)\(i)")?.cgImage {
                                                        let rebuild = self.rebuildCGImage(uiImage)
                                                        selectedImage = rebuild
                                                    }
                                                }
                                            } else {
                                                withAnimation {
                                                    selectedIndex = -1
                                                    selectedImage = nil
                                                }
                                            }
                                        }
                                    }
                                
                                if i == selectedIndex {
                                    RoundedRectangle(cornerRadius: 10)
                                        .frame(width: 8, height: 8)
                                        .foregroundStyle(.accent)
                                }
                            }
                        }
                        
                        
                        Button {
                            withAnimation {
                                selectedIndex = -1
                                selectedImage = nil
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .frame(width: 40, height: 40)
                                    .foregroundStyle(.accent.opacity( selectedImage == nil ? 0.2 : 0.8))
                                
                                Image(systemName: "circle.slash")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(.white)
                            }
                        }
                        
                        Rectangle()
                            .frame(width: 16, height: 40)
                            .foregroundStyle(.clear)
                        
                    } else {
                        HStack(spacing: 15) {
                            Text("+++").onTapGesture { subscriptions.isSubscribed = true }
                            Text("Privacy").onTapGesture { showPrivacy.toggle() }
                            Text("Terms").onTapGesture { showTerms.toggle() }
                            Text("Restore").onTapGesture {
                                Task {
                                    await subscriptions.restorePurchases()
                                }
                            }
                        }
                        .font(.footnote)
                        .opacity(0.7)
                    }
                    
                    
                }
            }
            .scrollIndicators(.never)
            .scrollClipDisabled(true)
            .scrollDisabled(showPaywall)
            .sheet(isPresented: $showTerms) { WebViewScreen(url: TERMS_CONDITIONS_LINK) }
            .sheet(isPresented: $showPrivacy) { WebViewScreen(url: PRIVACY_POLICY_LINK) }
            .padding(.vertical, 6)
            
        }.transition(.slide)
    }
    
    func rebuildCGImage(_ input: CGImage) -> CGImage? {
        let ciImage = CIImage(cgImage: input)
        let context = CIContext(options: nil)
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
    
}
