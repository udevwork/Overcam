import Foundation
import Metal
import MetalKit

final class MetalRenderer: NSObject, MTKViewDelegate {
    public let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState!
    private var samplerState: MTLSamplerState!
    private var textureCache: CVMetalTextureCache!
    private var lastDrawableSize: CGSize = .zero

    var currentTexture: MTLTexture?

    var referenceTexture: MTLTexture? = nil
    var referenceAlpha: Float = 0.0
    
    // масштаб для корректного отображения (Fit)
    private var scaleFactors: [Float] = [1.0, 1.0]

    private var scaleBuffer: MTLBuffer!
    private var library: MTLLibrary!
    private var pipelineCamera: MTLRenderPipelineState!
    private var pipelineReference: MTLRenderPipelineState!
    
    init(mtkView: MTKView) {
        self.device = mtkView.device!
        self.commandQueue = device.makeCommandQueue()!
        super.init()
        mtkView.delegate = self
        mtkView.framebufferOnly = false
        mtkView.colorPixelFormat = .bgra8Unorm
        buildPipeline(mtkView: mtkView)
        buildSamplerState()
        buildTextureCache()
        updateScaleBuffer()
    }

    func buildPipeline(mtkView: MTKView) {
        self.library = device.makeDefaultLibrary()

        let descCamera = MTLRenderPipelineDescriptor()
        descCamera.vertexFunction = library.makeFunction(name: "vertex_passthrough")
        descCamera.fragmentFunction = library.makeFunction(name: "fragment_camera")
        descCamera.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineCamera = try! device.makeRenderPipelineState(descriptor: descCamera)

        let descRef = MTLRenderPipelineDescriptor()
        descRef.vertexFunction = library.makeFunction(name: "vertex_passthrough") // тот же!
        descRef.fragmentFunction = library.makeFunction(name: "fragment_overlay")
        descRef.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineReference = try! device.makeRenderPipelineState(descriptor: descRef)
    }

    private func buildSamplerState() {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerState = device.makeSamplerState(descriptor: samplerDescriptor)
    }

    private func buildTextureCache() {
        CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
    }

    private func updateScaleBuffer() {
        scaleBuffer = device.makeBuffer(bytes: scaleFactors,
                                        length: MemoryLayout<Float>.size * 2,
                                        options: [])
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        lastDrawableSize = size
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let texture = currentTexture else { return }

        let commandBuffer = commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!

        // --- Камера ---
        updateScaleFactors(for: lastDrawableSize, textureWidth: texture.width, textureHeight: texture.height)

        let frameTexture = currentTexture! // захватываем один раз

        // Камера
        encoder.setRenderPipelineState(pipelineCamera)
        encoder.setVertexBytes(scaleFactors, length: MemoryLayout<Float>.size * 2, index: 0)
        encoder.setFragmentTexture(frameTexture, index: 0)
        encoder.setFragmentSamplerState(samplerState, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        // Reference
        if let ref = referenceTexture {
            encoder.setRenderPipelineState(pipelineReference)
            encoder.setVertexBytes(scaleFactors, length: MemoryLayout<Float>.size * 2, index: 0)
            encoder.setFragmentTexture(frameTexture, index: 0) // base
            encoder.setFragmentTexture(ref, index: 1)          // overlay
            encoder.setFragmentSamplerState(samplerState, index: 0)
            encoder.setFragmentSamplerState(samplerState, index: 1)
            encoder.setFragmentBytes(&referenceAlpha, length: MemoryLayout<Float>.size, index: 0)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        }

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func updateScaleFactors(for drawableSize: CGSize, textureWidth: Int, textureHeight: Int) {
        let imageAspect = Float(textureWidth) / Float(textureHeight)
        let viewAspect = Float(drawableSize.width) / Float(drawableSize.height)

        scaleFactors = [imageAspect / viewAspect, 1.0]
    }
    
    func makeTexture(from image: CGImage) -> MTLTexture? {
        print("🧩 Загружаем CGImage: \(image.width)x\(image.height)")

          let textureLoader = MTKTextureLoader(device: device)
          let options: [MTKTextureLoader.Option: Any] = [
              .SRGB : false
          ]

          do {
              let texture = try textureLoader.newTexture(cgImage: image, options: options)
              print("✅ Загружена MTLTexture: \(texture.width)x\(texture.height)")
              return texture
          } catch {
              print("❌ Ошибка: \(error)")
              return nil
          }
    }
}
