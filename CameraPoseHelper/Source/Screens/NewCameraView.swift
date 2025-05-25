import SwiftUI
import MetalKit
import Combine
import CoreVideo

struct NewCameraView: UIViewRepresentable {
    @ObservedObject var cameraManager: NewCameraManager

    func makeCoordinator() -> Coordinator {
        Coordinator(cameraManager: cameraManager)
    }

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        mtkView.delegate = context.coordinator.renderer
        mtkView.framebufferOnly = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        mtkView.preferredFramesPerSecond = 60
        mtkView.colorPixelFormat = .bgra8Unorm

        context.coordinator.renderer = MetalRenderer(mtkView: mtkView)
        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        guard let renderer = context.coordinator.renderer else { return }

        DispatchQueue.main.async {
            let scale = UIScreen.main.scale
            let size = uiView.bounds.size
            uiView.drawableSize = CGSize(width: size.width * scale, height: size.height * scale)
        }

        if let image = cameraManager.referenceImage {
            let newHash = image.hashValue
            
            renderer.referenceAlpha = cameraManager.referenceAlpha
            
            if newHash != context.coordinator.lastReferenceImageHash {
                context.coordinator.lastReferenceImageHash = newHash
                renderer.referenceTexture = renderer.makeTexture(from: image)
                print("Reference texture обновлена")
            }
        } else {
            renderer.referenceTexture = nil
            renderer.referenceAlpha = 0.0
        }
    }

    final class Coordinator: NSObject {
        let cameraManager: NewCameraManager
        var renderer: MetalRenderer?
        var lastReferenceImageHash: Int?
        private var cancellables = Set<AnyCancellable>()
        
        init(cameraManager: NewCameraManager) {
            self.cameraManager = cameraManager
            super.init()
            
            
            cameraManager.onNewPixelBuffer = { [weak self] pixelBuffer in
                self?.updateTexture(from: pixelBuffer)
            }
        }

        private func updateTexture(from pixelBuffer: CVPixelBuffer) {
            guard let renderer = renderer else { return }
            guard let textureCache = renderer.device.makeTextureCache() else { return }

            var cvTextureOut: CVMetalTexture?
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)

            CVMetalTextureCacheCreateTextureFromImage(
                kCFAllocatorDefault,
                textureCache,
                pixelBuffer,
                nil,
                .bgra8Unorm,
                width,
                height,
                0,
                &cvTextureOut
            )

            if let cvTextureOut,
               let metalTexture = CVMetalTextureGetTexture(cvTextureOut) {
                renderer.currentTexture = metalTexture
            }
        }
    }
}

struct VideoFrame : View {
    
    @EnvironmentObject var cameraManager: NewCameraManager
    @StateObject var screen: ScreenController
    var onSwipe: ()->()
    
    var body: some View {
        NewCameraView(cameraManager: cameraManager)
            .onChange(of: screen.showPaywall, { oldValue, newValue in
                DispatchQueue.global().async(execute: {
                    newValue ? cameraManager.stop() : cameraManager.start()
                })
            })
        
            .onAppear(perform: {
                cameraManager.start()
            })
            .opacity(cameraManager.isRunning ? 1.0 : 0)
            .onTapGesture(perform: { location in
                cameraManager.focus(at: location, viewSize: UIScreen.main.bounds.size)
            })
            .simultaneousGesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onEnded({ value in
                    onSwipe()
                }))
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        cameraManager.zoom = cameraManager.lastZoomLevel * value
                        cameraManager.setZoom()
                    }
                    .onEnded { _ in
                        cameraManager.zoom = max(1.0, min(cameraManager.zoom, 5.0))
                        cameraManager.lastZoomLevel = cameraManager.zoom
                    }
            )
    }
}

extension MTLDevice {
    func makeTextureCache() -> CVMetalTextureCache? {
        var cache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(nil, nil, self, nil, &cache)
        return cache
    }
}
