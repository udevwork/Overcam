//
//  PhotosTemplatePickerView.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 26.08.2024.
//

import SwiftUI
import PhotosUI
import BoilerCore


struct PhotosTemplatePickerView: View {
    @StateObject var model = Boiler.subscription
    @State var selectedIndex: Int = -1
    var photoPrefix: String = "photo-"
    
    @State private var photoItem: PhotosPickerItem? = nil
    @Binding var selectedImage: Image?
    @State var showPaywall: Bool = false
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .center, spacing: 10) {
                
                Rectangle()
                    .frame(width: 16, height: 40)
                    .foregroundStyle(.clear)
                
                
                if model.subscriptionStatus == .active {
                    PhotosPicker(selection: $photoItem) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(.accent)
                          
                            Image(systemName: "plus")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(.white)
                        }
                    }.onChange(of: photoItem) {
                        Task {
                            if let data = try? await photoItem?.loadTransferable(type: Data.self),
                               let img = UIImage(data: data) {
                                selectedImage = Image(uiImage: img)
                            } else {
                                print("Failed")
                            }
                        }
                    }
                } else {
                    Button {
                        showPaywall.toggle()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(.accent)
                          
                            Image(systemName: "plus")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(.white)
                        }
                    }

                }
               
                
                ForEach((0..<25)) { i in
                    VStack {
                        Image("\(photoPrefix)\(i)")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .onTapGesture {
                                withAnimation {
                                    selectedIndex = i
                                    selectedImage = Image("\(photoPrefix)\(i)")
                                }
                              
                            }
                        
                        if i == selectedIndex {
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: 8, height: 8)
                                .foregroundStyle(.accent)
                        }
                    }
                }
                
                Rectangle()
                    .frame(width: 16, height: 40)
                    .foregroundStyle(.clear)
                
            }
        }.scrollIndicators(.never)
//            .withOldPaywallOnTapFeature(show: $showPaywall)
            .withRemotePaywallOnTapFeature(show: $showPaywall)
    }
    
}
//
//#Preview {
//
//     PhotosTemplatePickerView(selectedImageName: .constant(""))
//}
