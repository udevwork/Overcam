//
//  ContentView.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 22.12.2023.
//

import SwiftUI
import Combine
import AVFoundation
import PhotosUI
import CompactSlider
import Foil



class ScreenController: ObservableObject {
    
    private var store = Set<AnyCancellable>()
    
    @FoilDefaultStorage(key: "onboardingComplete") var onboardingComplete = false
    @FoilDefaultStorage(key: "tutorComplete") var tutorComplete = false

    @Published var showPaywall = false
    @Published var showCamera = false
    
    init() {
        if onboardingComplete == true {
            showCamera = true
        }
        $onboardingComplete.sink { complete in
            if complete {
                withAnimation {
                    self.showCamera = true
                }
            }
        }.store(in: &store)
        
    }
    
}

struct CustomCameraView: View {
    
    @Namespace private var animationNamespace
    
    @StateObject var cameraManager: NewCameraManager = NewCameraManager()
    @StateObject var levelModel: LevelViewModel      = LevelViewModel()
    @StateObject var screen: ScreenController        = ScreenController()
    
    @State var menuOpened = false

    var body: some View {
        ZStack {
            
            if screen.showCamera {
                VStack(spacing: 0) {
                    
                    if menuOpened {
                        HeaderMenu()
                    }
                    
                    ZStack {
                        
                        VideoFrame(screen: screen, onSwipe: swipeMenu)
                        GridOverlay(showGrid: $cameraManager.grid)
                        TutorialArrowView(complete: $screen.tutorComplete)
                        
                        HStack {
                            Spacer()
                            VStack {
                                HStack {
                                    ZoomLabel()
                                    Spacer()
                                    if !menuOpened {
                                        LastCapturedImage()
                                    }
                                }
                                
                                Spacer()
                                
                                if menuOpened && !screen.showPaywall {
                                    SlidersStack()
                                }
                                
                                if !menuOpened {
                                    HStack(spacing: 30) {
                                        ReferenceImageOpacitySlider()
                                        Spacer()
                                        LevelIndicatorView(viewModel: levelModel)
                                        CaptureButton(cameraViewAvalable: $cameraManager.permissionGranted) {
                                            cameraManager.captureHighQualityPhoto()
                                        }
                                    }.transition(.blurReplace)
                                }
                                
                            }
                        }.padding(20)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                    
                    if menuOpened {
                        PhotosTemplatePickerView(
                            selectedImage: $cameraManager.referenceImage,
                            showPaywall: $screen.showPaywall,
                            namespace: animationNamespace
                        )
                    }
                }
                
                
                CameraPermission()
                
                
            }

            if screen.showPaywall {
                BestPaywall(
                    namespace: animationNamespace,
                    showPaywall: $screen.showPaywall
                )
            }
            
            if screen.onboardingComplete == false {
                VideoOnboarding(onboardingComplete: $screen.onboardingComplete)
            }
            
        }.environmentObject(cameraManager)
    }
    
    func swipeMenu() {
        if screen.showPaywall {return}
        hapticLight()
        withAnimation {
            menuOpened.toggle()
            screen.tutorComplete = true
            screen.onboardingComplete = true
        }
        menuOpened ? levelModel.stop() : levelModel.start()
    }
}

