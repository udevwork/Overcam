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

final class CameraModel: ObservableObject {
    
    @FoilDefaultStorage(key: "tutorComplete") var tutorComplete = false
    
    @Published var permissionGranted: Bool? = nil
    
    init() {
        
    }
    
    func checkCameraPremission() {
        let mediaType: AVMediaType = .video
        let currentAccsess = AVCaptureDevice.authorizationStatus(for: mediaType)
        
        if currentAccsess == .authorized {
            DispatchQueue.main.async {
                withAnimation {
                    self.permissionGranted = true
                }
            }
        } else {
            AVCaptureDevice.requestAccess(for: mediaType) { granded in
                if granded {
                    DispatchQueue.main.async {
                        withAnimation {
                            self.permissionGranted = true
                        }
                    }
                }
            }
        }
    }
}

class ScreenController: ObservableObject {
    
    private var store = Set<AnyCancellable>()
    
    @Published var showPaywall = false
    @Published var showOnboarding = true
    @Published var showCamera = false
    
    init() {
        $showOnboarding.sink {
            if !$0 {
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
    @StateObject var viewModel: CameraModel          = CameraModel()
    
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
                        TutorialArrowView(complete: $viewModel.tutorComplete)
                        
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
                                        CaptureButton(cameraViewAvalable: $viewModel.permissionGranted) {
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
                .onAppear {
                    self.viewModel.checkCameraPremission()
                }
            }
            
            if screen.showPaywall {
                BestPaywall(
                    namespace: animationNamespace,
                    showPaywall: $screen.showPaywall
                )
            }
            
            if screen.showOnboarding {
                VideoOnboarding(showOnboarding: $screen.showOnboarding)
            }
            
        }.environmentObject(cameraManager)
    }
    
    func swipeMenu() {
        if screen.showPaywall {return}
        hapticLight()
        withAnimation {
            menuOpened.toggle()
            viewModel.tutorComplete = true
        }
        menuOpened ? levelModel.stop() : levelModel.start()
    }
}

