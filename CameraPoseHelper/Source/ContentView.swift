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
import BoilerCore
import Foil

final class CameraModel: ObservableObject {
  
    @FoilDefaultStorage(key: "tutorComplete") var tutorComplete = false
    @FoilDefaultStorage(key: "firstRaitingComplete") var firstRaitingComplete = false

    
    @Published var cameraViewAvalable: Bool = false
    @Published var cameraAccsessProccessComplete: Bool = false
    @Published var lastTakenImage: Image? = nil
    
    @Published var showRating = false

    
    @Published var manager: CameraManager = .init(
            outputType: .photo,
            cameraPosition: .back,
            cameraFilters: [],
            resolution: .hd4K3840x2160,
            frameRate: 25,
            flashMode: .off,
            isGridVisible: false,
            focusImageColor: .accent,
            focusImageSize: 92
    )
    
    private var store = Set<AnyCancellable>()
    
    init() {
        
    }
    
    func checkCameraPremission() {
        let accsess = AVCaptureDevice.authorizationStatus(for: .video)
    
        if accsess == .authorized {
            DispatchQueue.main.async {
                withAnimation {
                    self.cameraViewAvalable = true
                    self.cameraAccsessProccessComplete = true
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
                        self.manager.checkPermissions()
                    })
                  
                }
            }
            self.att()
        } else {
            AVCaptureDevice.requestAccess(for: .video) { granded in
                if granded {
                    DispatchQueue.main.async {
                        withAnimation {
                            self.cameraViewAvalable = true
                            self.cameraAccsessProccessComplete = true
                            DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
                                self.manager.checkPermissions()
                            })
                        }
                    }
                    self.att()
                } else {
                    DispatchQueue.main.async {
                        withAnimation {
                            self.cameraAccsessProccessComplete = true
                        }
                    }
                }
            }
        }
    }
    
    func att() {
        DispatchQueue.main.asyncAfter(deadline: .now()+2, execute: {
            Task {
                await TrackingPermissionService.shared.checkAttPermissions()
            }
        })
    }
    
    func takePicture(data: UIImage) {
        self.lastTakenImage = Image(uiImage: data)
        DispatchQueue.global(qos: .background).async {
            UIImageWriteToSavedPhotosAlbum(data, nil, nil, nil)
            print("IMAGE SAVED")
            
            if self.firstRaitingComplete == false {
                DispatchQueue.main.asyncAfter(deadline: .now()+3, execute: {
                    self.showRating = true
                    self.firstRaitingComplete = true
                })
            }
            
        }
    }
    
}

struct CameraView: View {
    
    @StateObject var model = CameraModel()
    
    var body: some View {
        
        MCameraController(manager: model.manager)
            .cameraScreen({ manager, nameid, closeControllerAction in
                return CustomCameraView(
                    cameraManager: manager,
                    viewModel: model,
                    namespace: nameid,
                    closeControllerAction: closeControllerAction,
                    lastTakenImage: $model.lastTakenImage
                )
            })
            .mediaPreviewScreen(nil)
            .onImageCaptured(model.takePicture)
 
    }
    
}

struct CustomCameraView: MCameraView {
    
    @StateObject var cameraManager: CameraManager
    @StateObject var viewModel: CameraModel
    let namespace: Namespace.ID
    let closeControllerAction: () -> ()
    
    @State private var changeMirror: Bool = false
    @State private var finalAmount = 1.0
    
    // Zoom
    @State private var zoom = 1.0
    @State private var lastZoomLevel: CGFloat = 1.0
    @State private var zoomLabelAnimation: CGFloat = 0.0
    
    @State private var flash: Bool = false
    @State private var grid: Bool = false
    @State private var front: Bool = false
    @State private var expBias: Double = 1.0
    
    @State private var showSlider: Bool = false
    @State private var onTouchBottomZone: Bool = false
    
    @State var menuOpened = false
    
    @State private var customUserImageImage: Image?
    @Binding var lastTakenImage: Image?
    
    var topIconsSize: CGFloat = 18
    
    var body: some View {
        VStack(spacing: 0) {
           
            if menuOpened {
                
                HStack(spacing: 20) {
                    Button {
                        flash.toggle()
                        do {
                            try self.changeFlashMode(flash ? .on : .off)
                        } catch {
                            
                        }
                    } label: {
                        
                        Image(systemName: flash ? "bolt.fill" : "bolt.slash")
                            .resizable()
                            .frame(width: topIconsSize, height: topIconsSize)
                            .fontDesign(.rounded)
                    }
                    
                    Button {
                        changeMirror.toggle()
                        self.changeMirrorOutputMode(changeMirror)
                    } label: {
                        if changeMirror {
                            Image(systemName: "flip.horizontal.fill")
                                .resizable()
                                .frame(width: topIconsSize, height: topIconsSize)
                        } else {
                            Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                                .resizable()
                                .frame(width: topIconsSize, height: topIconsSize)
                        }
                    }
                    
                    Button {
                        grid.toggle()
                        self.changeGridVisibility(grid)
                    } label: {
                        if grid {
                            Image(systemName: "grid")
                                .resizable()
                                .frame(width: topIconsSize, height: topIconsSize)
                        } else {
                            Image(systemName: "grid")
                                .resizable()
                                .frame(width: topIconsSize, height: topIconsSize)
                                .opacity(0.5)
                            
                        }
                    }
                    
                    Button {
                        front.toggle()
                        try? self.changeCamera(front ? .front : .back)
                    } label: {
                        if front {
                            Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: topIconsSize, height: topIconsSize)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: topIconsSize, height: topIconsSize)
                        }
                    }
                    
                    Button {
                        withAnimation {
                            showSlider.toggle()
                        }
                    } label: {
                        if showSlider {
                            Image(systemName: "slider.horizontal.below.sun.max")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: topIconsSize, height: topIconsSize)
                        } else {
                            Image(systemName: "slider.horizontal.below.sun.max")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: topIconsSize, height: topIconsSize)
                                .opacity(0.5)
                        }
                    }
                    
                    Spacer()
                
                    
                    NavigationLink {
                        SettingsScreenView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: topIconsSize, height: topIconsSize)
                    }

                }
                .foregroundStyle(.accent)
                .padding()
                .transition(.blurReplace)
            }
            ZStack {
               
                customUserImageImage?
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .transition(.blurReplace)
                
                if viewModel.cameraAccsessProccessComplete {
                    if viewModel.cameraViewAvalable {
                        createCameraView()
                            .opacity(onTouchBottomZone ? 1 : finalAmount)
                            .simultaneousGesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                .onEnded({ value in
                                    
                                    if value.translation.height < 0 {
                                        swipeMenuUp()
                                
                                    }
                                    
                                    if value.translation.height > 0 {
                                        swipeMenuDown()
                                        
                                    }
                                }))
                            .simultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        zoom = lastZoomLevel * value
                                        withAnimation {
                                            zoomLabelAnimation = 1
                                        }
                                    }
                                    .onEnded { _ in
                                        zoom = max(1.0, min(zoom, 5.0))
                                        lastZoomLevel = zoom
                                        withAnimation {
                                            zoomLabelAnimation = 0
                                        }
                                    }
                            )
                        
                        if viewModel.tutorComplete == false {
                            TutorView().transition(.blurReplace)
                        }
                    } else {
                        CameraAccessPlaceholderView()
                            
                    }
                }
                
                HStack {
                    Spacer()
                    VStack {
             
                        HStack {
                            Text(String(format: "%.2f", zoom))
                                .bold()
                                .font(.footnote)
                                .fontDesign(.monospaced)
                                .opacity(zoomLabelAnimation)
                            
                            Spacer()
                            Button(action: {
                                UIApplication.shared.open(URL(string:"photos-redirect://")!)
                            }) {
                                lastTakenImage?.resizable()
                                    .clipShape(Circle())
                                
                                    .frame(width: 40, height: 40, alignment: .center)
                                
                            }
                            .transition(.blurReplace)
                          
                        }  .padding(30)
                       
                        Spacer()
                       
                        if menuOpened {
                            
                            VStack(spacing: 3) {
                                
                                if showSlider {
                                 
                                    CompactSlider(value: $expBias, in: -10.0...10.0) {
                                        Text("Exposure").font(.footnote)
                                        Spacer()
                                        Text(String(format: "%.2f", expBias)).font(.footnote)
                                    }
                                    .compactSliderStyle(.custom)
                                    .onChange(of: expBias, {
                                        do {
                                            try self.changeExposureTargetBias(Float(expBias))
                                        } catch {
                                            
                                        }
                                    })
                                    .transition(.blurReplace)
                                }
                                
                                if (customUserImageImage != nil) {
                                    CompactSlider(value: $finalAmount) {
                                        Text("Opacity").font(.footnote)
                                        Spacer()
                                        Text(String(format: "%.2f", finalAmount)).font(.footnote)
                                    }
                                   
                                    .compactSliderStyle(.custom)
                                    .transition(.blurReplace)
                                }
                            }
                            .padding(.vertical, 15)
                            .padding(.horizontal, 10)
                          
                            
                        }
                        
                        
                        if menuOpened == false {
                           
                            HStack(spacing: 30) {
                                
                                if (customUserImageImage != nil) {
                                    CompactSlider(value: $finalAmount) {
                                        Text("Opacity").font(.footnote)
                                        Spacer()
                                        Text(String(format: "%.2f", finalAmount)).font(.footnote)
                                    }
                                    .compactSliderStyle(.custom)
                                }
                                Spacer()
                                Button(action: captureOutput) {
                                    ZStack {
                                        Circle()
                                            .frame(width: 40, height: 40, alignment: .center)
                                            .foregroundStyle(.accent)
                                        if viewModel.cameraAccsessProccessComplete == false {
                                            ProgressView()
                                        }
                                    }
                                    
                                }
                                .disabled(!viewModel.cameraViewAvalable)
                                .opacity(viewModel.cameraViewAvalable ? 1.0 : 0.5)
                               
                                
                            }
                            .padding(30)
                            .transition(.blurReplace)
                            .background {
                                LinearGradient(colors: [.black.opacity(0.3),.clear], startPoint: .bottom, endPoint: .top)
                                        .frame(height: 100)
                                        .gesture(
                                            DragGesture(minimumDistance: 0)
                                                .onChanged { _ in
                                                    if !onTouchBottomZone {
                                                        withAnimation {
                                                            onTouchBottomZone = true
                                                        }
                                            
                                                    }
                                                }
                                                .onEnded { _ in
                                                    withAnimation {
                                                        onTouchBottomZone = false
                                                    }
                                   
                                                }
                                        )
                                        .blur(radius: 5)
                                
                            }
                        }
                        
                    }
                }
                .frame(width: UIScreen.main.bounds.width)
                

                
            }
            .frame(width: UIScreen.main.bounds.width)
            .clipShape(RoundedRectangle(cornerRadius: 40))
            .onChange(of: zoom, {
                do {
                    try self.changeZoomFactor(zoom)
                } catch {
                    
                }
            })
            
            if menuOpened {
                VStack {
                    Rectangle().foregroundStyle(.clear)
                        .frame(width: 0, height: 5)
                    PhotosTemplatePickerView(selectedImage: $customUserImageImage)
                        .padding(.vertical, 6)
                        
                        .onChange(of: customUserImageImage, {
                            finalAmount = 0.5
                        })
                        .disabled(!viewModel.cameraViewAvalable)
                    
                }.transition(.slide)
            }
        
        }
        .onAppear(perform: {
            self.viewModel.checkCameraPremission()
        })
        .withRatingFeature(showRating: $viewModel.showRating)
            .withOnboardingFeature()
    }
  
    func swipeMenuUp() {
        withAnimation {
            menuOpened.toggle()
            viewModel.tutorComplete = true
        }
        
    }
    
    func swipeMenuDown() {
        withAnimation {
            menuOpened.toggle()
            viewModel.tutorComplete = true
        }
    }
}


#Preview {
    CameraView().preferredColorScheme(.dark)
}
