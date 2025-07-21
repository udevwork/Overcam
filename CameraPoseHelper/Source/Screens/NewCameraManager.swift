import Foundation
import AVFoundation
import Photos
import CoreImage
import Metal
import MetalKit
import SwiftUI
import Combine

@objcMembers
final class NewCameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject {
    
    private let photoOutput = AVCapturePhotoOutput()
    
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    public var deviceInput: AVCaptureDeviceInput?
    private let ciContext = CIContext()
    private var textureCache: CVMetalTextureCache?
    
    public var availableDevices: [AVCaptureDevice] = []
    
    //@Published var currentPixelBuffer: CVPixelBuffer?
    var onNewPixelBuffer: ((CVPixelBuffer) -> Void)? = nil
    
    @Published var permissionGranted: Bool? = nil
    @Published var permissionPhotoGranted: Bool? = nil
    @Published var currentdevice: AVCaptureDevice?
    @Published var isRunning = false
    @Published var referenceImage:  CGImage?
    @Published var referenceAlpha: Float = 0.5
    @Published var camExpRange: (CMTime,CMTime) = (.zero,.zero)
    @Published var lastCapturedImage: UIImage?
    @Published var zoom:CGFloat = 1.0
    @Published var lastZoomLevel: CGFloat = 1.0
    @Published var flash: Bool = false
    @Published var grid: Bool = false
    @Published var front: Bool = false
    @Published var expBias: Double = 0.005
    @Published var iso: Float = 200.0
    @Published var focusLocked: Bool = false
    
    private var store = Set<AnyCancellable>()
    
    private let videoProcessingQueue = DispatchQueue(label: "camera.frame.processing")
    
    override init() {
        super.init()
        $permissionGranted.sink { complete in
             if complete == true {
                 self.setupSession()
             }
         }.store(in: &store)
         
    }

    func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        // Найти устройства (камеры)
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera],
            mediaType: .video,
            position: .back
        )
        availableDevices = discoverySession.devices

        guard let defaultDevice = availableDevices.first else {
            print("No available cameras!")
            session.commitConfiguration()
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: defaultDevice)
            if session.canAddInput(input) {
                session.addInput(input)
                deviceInput = input
            }
            self.currentdevice = defaultDevice
        } catch {
            print("Error setting device input: \(error)")
        }

        if session.canAddOutput(videoOutput) {
            videoOutput.setSampleBufferDelegate(self, queue: videoProcessingQueue)
            session.addOutput(videoOutput)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            if let connection = videoOutput.connection(with: .video) {
                if #available(iOS 17.0, *) {
                    connection.videoRotationAngle = 90
                } else if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
        }

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }
        
        self.camExpRange = getExpRange()
        
        session.commitConfiguration()
        
        CVMetalTextureCacheCreate(nil, nil, MTLCreateSystemDefaultDevice()!, nil, &textureCache)
        
        start()
    }
    
    func checkPhotoLibraryAccess() {
        let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        DispatchQueue.main.async {
            withAnimation {
                self.permissionPhotoGranted = (current == .authorized || current == .limited)
            }
        }
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
                } else {
                    withAnimation {
                        self.permissionGranted = false
                    }
                }
            }
        }
    }
    
    func getCurrentPermissions(){
        let mediaType: AVMediaType = .video
        let currentAccsess = AVCaptureDevice.authorizationStatus(for: mediaType)
        permissionGranted = (currentAccsess == .authorized)
    }
    
    func start() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
            DispatchQueue.main.async {
                withAnimation {
                    self.isRunning = true
                }
            }
        }
     
    }

    func stop() {
        guard session.isRunning else { return }
        DispatchQueue.main.async {
            withAnimation {
                self.isRunning = false
            }
        }
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now()+0.35, execute: {
            self.session.stopRunning()
        })
    }

    func switchCamera(to deviceType: AVCaptureDevice.DeviceType) {
        guard let device = availableDevices.first(where: { $0.deviceType == deviceType }) else {
            print("Requested device type not available")
            return
        }

        session.beginConfiguration()
        if let currentInput = deviceInput {
            session.removeInput(currentInput)
        }

        do {
            let newInput = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                deviceInput = newInput
            }
        } catch {
            print("Error switching cameras: \(error)")
        }

        session.commitConfiguration()
    }

    func captureHighQualityPhoto() {
        let settings = AVCapturePhotoSettings()

//        settings.isHighResolutionPhotoEnabled = true
//        settings.isAutoStillImageStabilizationEnabled = true

        if photoOutput.supportedFlashModes.contains(.auto) {
            settings.flashMode = flash ? .on : .off
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    

    private func saveImageToPhotos(image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()
            if let data = image.heicData() {
                request.addResource(with: .photo, data: data, options: nil)
            } else if let jpegData = image.jpegData(compressionQuality: 0.9) {
                request.addResource(with: .photo, data: jpegData, options: nil)
            }
        }, completionHandler: { success, error in
            if success {
                print("Saved photo to library!")
            } else {
                print("Error saving photo: \(String(describing: error))")
            }
        })
    }
    
    
    private let textureConvertQueue = DispatchQueue(label: "texture.convert", qos: .userInitiated)

    @objc dynamic
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pb = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        textureConvertQueue.async {
          autoreleasepool {
            self.onNewPixelBuffer?(pb)
          }
        }
    }
}


extension NewCameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error = error {
            print("❌ Ошибка при захвате фото: \(error)")
            return
        }
        
        guard let data = photo.fileDataRepresentation() else {
            print("❌ Не удалось получить данные фото")
            return
        }
        
        PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: data, options: nil)
            
        } completionHandler: { success, error in
            if success {
                print("✅ Фото сохранено в галерею!")
                if let fullImage = UIImage(data: data) {
                    let thumbnail = fullImage.preparingThumbnail(of: CGSize(width: 80, height: 80))
                    DispatchQueue.main.async {
                        withAnimation {
                            self.lastCapturedImage = thumbnail
                        }
                    }
                }
                haptic()
            } else {
                print("❌ Ошибка при сохранении фото: \(String(describing: error))")
                self.checkPhotoLibraryAccess()
            }
        }
    }
}

extension AVCaptureDevice {
    /// Возвращает номинальный зум-фактор камеры в понятной форме (0.5, 1.0, 2.0 и т.д.)
    var nominalZoom: Float {
        switch deviceType {
        case .builtInUltraWideCamera:
            return 0.5
        case .builtInWideAngleCamera:
            return 1.0
        case .builtInTelephotoCamera:
            return 2.0 // Может быть и 3.0, но без проверки модели устройства — 2.0 по умолчанию
        default:
            return 1.0
        }
    }
}

// MARK: - Helper

import UniformTypeIdentifiers
import UIKit

extension UIImage {
    func heicData() -> Data? {
        let options: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: 0.9]
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, AVFileType.heic as CFString, 1, nil) else { return nil }
        if let cgImage = self.cgImage {
            CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
            guard CGImageDestinationFinalize(destination) else { return nil }
            return data as Data
        }
        return nil
    }
}

// MARK: - Настройки камеры

extension NewCameraManager {
    
    func setZoom() {
        guard let device = deviceInput?.device else { return }

        let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 6.0) // 6x — лимит безопасности
        let minZoom: CGFloat = 1.0

        let clamped = max(min(zoom, maxZoom), minZoom)

        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = clamped
            device.unlockForConfiguration()
        } catch {
            print("❌ Не удалось установить зум: \(error)")
        }
    }
    
    func setTorch(active: Bool) {
        guard let device = deviceInput?.device,
              device.hasTorch, device.isTorchAvailable else {
            print("❌ Torch not available on this device")
            return
        }

        do {
            try device.lockForConfiguration()

            if active {
                try device.setTorchModeOn(level: 1.0) // максимум яркости
            } else {
                device.torchMode = .off
            }

            device.unlockForConfiguration()
        } catch {
            print("❌ Torch configuration failed: \(error)")
        }
    }
    
    func switchToFrontCamera() {
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("❌ Фронтальная камера не найдена")
            return
        }

        reswitchCamera(to: frontCamera)
    }
    
    func switchToBackCamera() {
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("❌ Основная камера не найдена")
            return
        }

        reswitchCamera(to: backCamera)
    }
    
    func reswitchCamera(to newDevice: AVCaptureDevice) {
        session.beginConfiguration()

        if let currentInput = deviceInput {
            session.removeInput(currentInput)
        }

        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                deviceInput = newInput
                currentdevice = newDevice
            } else {
                print("⚠️ Cannot add new camera input")
            }
        } catch {
            print("⚠️ Failed to create input: \(error)")
        }

        // Не забудь выставить ориентацию после смены камеры
        if let connection = videoOutput.connection(with: .video) {
            if #available(iOS 17.0, *) {
                connection.videoRotationAngle = 90
            } else if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }

        session.commitConfiguration()
    }
    
    
    func setCustomExposure() {
        guard let device = deviceInput?.device else { return }

        let format = device.activeFormat
        let minDuration = format.minExposureDuration
        let maxDuration = format.maxExposureDuration
        let clampedDuration = min(max(expBias.asCMTime, minDuration), maxDuration)

        let minISO = format.minISO
        let maxISO = format.maxISO
        let clampedISO = min(max(iso, minISO), maxISO)

        do {
            try device.lockForConfiguration()

            if device.isExposureModeSupported(.custom) {
                device.setExposureModeCustom(duration: clampedDuration, iso: clampedISO, completionHandler: nil)
                print("📸 Exposure set: \(CMTimeGetSeconds(clampedDuration))s @ ISO \(clampedISO) (range: \(minISO)–\(maxISO))")
            }

            device.unlockForConfiguration()
        } catch {
            print("⚠️ Не удалось установить экспозицию: \(error)")
        }
    }

    
    func getExpRange() -> (CMTime,CMTime){
        guard let device = deviceInput?.device else { return (.zero,.zero) }
        let range = (device.activeFormat.minExposureDuration,
        device.activeFormat.maxExposureDuration)
        return range
    }
    
    func setAutoExposure() {
        guard let device = deviceInput?.device else { return }

        do {
            try device.lockForConfiguration()

            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }

            device.unlockForConfiguration()
        } catch {
            print("⚡️ Не удалось вернуть автоэкспозицию: \(error)")
        }
    }
    
    func focus(at point: CGPoint, viewSize: CGSize) {
        guard let device = deviceInput?.device else { return }

          do {
              try device.lockForConfiguration()

              let normalizedPoint = CGPoint(x: point.y / viewSize.height, y: 1.0 - point.x / viewSize.width)

              if device.isFocusPointOfInterestSupported {
                  device.focusPointOfInterest = normalizedPoint
                  device.focusMode = .autoFocus
              }

              if device.isExposurePointOfInterestSupported {
                  device.exposurePointOfInterest = normalizedPoint
                  device.exposureMode = .continuousAutoExposure
              }
              self.focusLocked = true
              device.unlockForConfiguration()
          } catch {
              print("⚡️ Ошибка фокуса/экспозиции: \(error)")
              self.focusLocked = true
          }
    }
    
    func unlockFocus() {
        guard let device = deviceInput?.device else { return }

          do {
              try device.lockForConfiguration()
              if device.isFocusPointOfInterestSupported {
                  device.focusMode = .continuousAutoFocus
              }

              if device.isExposurePointOfInterestSupported {
                  device.exposureMode = .autoExpose
              }
              device.unlockForConfiguration()
              focusLocked = false
          } catch {
              print("⚡️ Ошибка фокуса/экспозиции: \(error)")
          }
    }
    
}

extension CMTime {
    var asSeconds: Double {
        return CMTimeGetSeconds(self)
    }
}

extension Double {
    var asCMTime: CMTime {
        CMTimeMakeWithSeconds(self, preferredTimescale: 1_000_000_000)
    }
}

extension Double {
    var asExposureString: String {
        if self >= 1.0 {
            return String(format: "%.1fs", self)
        } else if self > 0 {
            let denominator = Int((1.0 / self).rounded())
            return "1/\(denominator)s"
        } else {
            return "0s"
        }
    }
}
