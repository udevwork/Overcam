//
//  Public+MCameraMedia.swift of MijickCameraView
//
//  Created by Tomasz Kurylik
//    - Twitter: https://twitter.com/tkurylik
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//
//  Copyright ©2024 Mijick. Licensed under MIT License.


import AVKit

public struct MCameraMedia {
    private let data: Any

    init?(data: Any?) { switch data {
        case .some(let data): self.data = data
        case nil: return nil
    }}
}

// MARK: - Access to Data
public extension MCameraMedia {
    var image: UIImage? { data as? UIImage }
    var video: URL? { data as? URL }
}

// MARK: - Image Initialiser
extension MCameraMedia {
    static func create(imageData: AVCapturePhoto, orientation: CGImagePropertyOrientation, filters: [CIFilter]) -> Self? {
        guard let imageData = imageData.fileDataRepresentation(),
              let ciImage = CIImage(data: imageData)
        else { return nil }

        let capturedCIImage = prepareCIImage(ciImage, filters)
        let capturedCGImage = prepareCGImage(capturedCIImage)
        let capturedUIImage = prepareUIImage(capturedCGImage, orientation)

        let capturedMedia = MCameraMedia(data: capturedUIImage)
        return capturedMedia
    }
}
private extension MCameraMedia {
    static func prepareCIImage(_ ciImage: CIImage, _ filters: [CIFilter]) -> CIImage {
        ciImage.applyingFilters(filters)
    }
    static func prepareCGImage(_ ciImage: CIImage) -> CGImage? {
        CIContext().createCGImage(ciImage, from: ciImage.extent)
    }
    static func prepareUIImage(_ cgImage: CGImage?, _ orientation: CGImagePropertyOrientation) -> UIImage? {
        guard let cgImage else { return nil }

        let orientation = UIImage.Orientation(orientation)
        let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
        return uiImage
    }
}

// MARK: - Video Initialiser
extension MCameraMedia {
    static func create(videoData: URL, filters: [CIFilter]) async -> Self? { await withCheckedContinuation { task in
        if filters.isEmpty { return task.resume(returning: .init(data: videoData)) }

        let asset = AVAsset(url: videoData)
        AVVideoComposition.applyFilters(
            to: asset,
            applyFiltersAction: { applyFiltersToVideo($0, filters) },
            completionHandler: { onFiltersApplied(task, asset, $0, $1) }
        )
    }}
}
private extension MCameraMedia {
    static func applyFiltersToVideo(_ request: AVAsynchronousCIImageFilteringRequest, _ filters: [CIFilter]) {
        let videoFrame = prepareVideoFrame(request, filters)
        request.finish(with: videoFrame, context: nil)
    }
    static func onFiltersApplied(_ task: CheckedContinuation<MCameraMedia?, Never>, _ asset: AVAsset, _ composition: AVVideoComposition?, _ error: (any Error)?) {
        guard error == nil,
              let composition,
              let fileUrl = prepareFileUrl(),
              let exportSession = prepareAssetExportSession(asset, fileUrl, composition)
        else { return task.resume(returning: nil) }

        exportSession.exportAsynchronously { onAssetExported(task, fileUrl) }
    }
}
private extension MCameraMedia {
    static func prepareVideoFrame(_ request: AVAsynchronousCIImageFilteringRequest, _ filters: [CIFilter]) -> CIImage { request
        .sourceImage
        .clampedToExtent()
        .applyingFilters(filters)
    }
    static func prepareFileUrl() -> URL? {
        FileManager.prepareURLForVideoOutput()
    }
    static func prepareAssetExportSession(_ asset: AVAsset, _ fileUrl: URL?, _ composition: AVVideoComposition?) -> AVAssetExportSession? {
        let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1920x1080)
        export?.outputFileType = .mov
        export?.outputURL = fileUrl
        export?.videoComposition = composition
        return export
    }
    static func onAssetExported(_ task: CheckedContinuation<MCameraMedia?, Never>, _ fileUrl: URL) {
        task.resume(returning: .init(data: fileUrl))
    }
}

// MARK: - Equatable
extension MCameraMedia: Equatable {
    public static func == (lhs: MCameraMedia, rhs: MCameraMedia) -> Bool { lhs.image == rhs.image && lhs.video == rhs.video }
}
