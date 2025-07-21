//
//  BestPaywall.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 03.05.2025.
//

import SwiftUI

class BestPaywallModel: ObservableObject {
    
    @Published public var selectedProduct : SubscriptionProduct? = nil
    @Published public var priceText : String = ""
    @Published public var durationText : String = ""
    
    init(){
        
    }
    
}

struct BestPaywall: View {
    
    @StateObject private var videoModel = LoopVideoPlayerModel("paywallvideo")

    @StateObject var subscriptionManager = SubscriptionManager.shared
    @StateObject var model = BestPaywallModel()
    
    let namespace: Namespace.ID
    @Binding var showPaywall: Bool
    
    @State var animate: Bool = false
    
    var body: some View {
        VStack {
            ZStack(alignment: .top) {
                
                if animate {
                    ZStack(alignment: .bottom) {
                        AVPlayerContainerView(player: videoModel.getPlayer())
                    }
                    .frame(width: UIScreen.main.bounds.width,
                           height: floor(UIScreen.main.bounds.height/3))
                    .mask(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .clipped(antialiased: true)
                    )
                }
                
                VStack(alignment: .leading, spacing: 30) {
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("Premium.")
                                .font(.doto(.black, size: 45))
                                .foregroundStyle(
                                    LinearGradient(colors: [Color.introOne,Color.introTwo], startPoint: .leading, endPoint: .trailing)
                                )
                        }
                        
                        Text(String(localized: "Become a part of our team and community"))
                            .font(.footnote)
                            .opacity(0.7)
                        
                    }
                    
    
                    Text(String(localized: "Unlock the photo selection feature from your own gallery. Choose references from your own photos."))
                        .font(.system(size: 15, weight: .regular, design: .default))
                    
                    if let error = subscriptionManager.errorMessage {
                        Text("error: \(error)")
                            .font(.system(size: 15, weight: .regular, design: .default))
                            .foregroundStyle(.accent)
                    }
                    
                    if subscriptionManager.isSubscribed {
                        Text(String(localized: "Thanks! Now you're with us! The subscription has been purchased."))
                            .font(.system(size: 15, weight: .bold, design: .default))
                    }
                    
                    HStack {
                        ForEach(subscriptionManager.products, id: \.id) { item in
                            VStack (alignment: .leading) {
                                Text(String(localized: .init(item.duration)))
                                    .bold()
                                if item.discount == "0%" {
                                    if let trial = item.trialDuration {
                                        Text("\(String(localized: .init(trial))) \(String(localized: .init("Trial")))")
                                            .layoutPriority(100)
                                            .font(.footnote)
                                    }
                                } else {
                                    Text("-\(item.discount ?? "-")")
                                }
                            }
                            .padding(.vertical,7)
                            .padding(.horizontal,12)
                            .frame(height: 80)
                            .background(.gray.opacity(0.15))
                            .cornerRadius(8)
                            .overlay(content: {
                                if model.selectedProduct == item {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(.accent, lineWidth: 1)
                                        .transition(.blurReplace)
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(.clear, lineWidth: 4)
                                        .transition(.blurReplace)
                                }
                            })
                            .frame(height: 100)
                            .onTapGesture {
                                withAnimation {
                                    model.selectedProduct = item
                                }
                                let p = item.priceString
                                let d = item.duration
                                let t = item.trialDuration
                                let o = item.discount ?? ""
                                
                                withAnimation() {
                                    model.priceText = "\(p)"
                                    model.durationText = "\(d)"
                                }
                            }
                            
                        }
                    }
                    
                    
                    
                    
                    Divider()
                    
                    
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                             
                                Text("\(model.priceText) / \(String(localized: .init(model.durationText)))")
                                    .font(.system(size: 21, weight: .bold, design: .serif))
                                    .contentTransition(.numericText())
                                
                            }
                    
                        }
                        Spacer()
                        Button {
                            if let product = model.selectedProduct {
                                Task {
                                    await subscriptionManager.purchase(product)
                                }
                            }
                        } label: {
                            HStack {
                                if subscriptionManager.purchasing == false {
                                    Text(String(localized: "Subscribe"))
                                        .bold()
                                        .foregroundStyle(.black)
                                } else {
                                    ProgressView()
                                }
                            }
                            .padding()
                            .background(.orangeRed)
                            .cornerRadius(40)
                        }
                        
                    }
                }
                .padding(20)
                .foregroundStyle(.black)
            }
            .background(content: {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .matchedGeometryEffect(id: "rectangle", in: namespace, isSource: showPaywall)
                
                    .foregroundStyle(.clear)
            })
            .preferredColorScheme(.dark)
            .onAppear {
                model.selectedProduct = subscriptionManager.products.first
                let p = model.selectedProduct?.priceString ?? "-"
                let d = model.selectedProduct?.duration ?? "-"
                
                model.priceText = "\(p)"
                model.durationText = "\(d)"
                
                withAnimation(.easeInOut.delay(0.3)) {
                    animate = true
                }
                
            }
            .onChange(of: showPaywall) {
                if showPaywall == false {
                    animate = showPaywall
                }
            }
            .onChange(of: subscriptionManager.isSubscribed) {
                
                withAnimation {
                    showPaywall = false
                }
                
            }
            Rectangle().frame(height: 50).foregroundStyle(.clear)
        }
    }
    
}

#Preview {
    @Previewable @Namespace var animationNamespace
    BestPaywall(namespace: animationNamespace, showPaywall: .constant(true))
}
