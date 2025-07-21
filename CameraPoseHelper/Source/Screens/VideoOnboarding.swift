// VideoPlayerModule.swift
// Полная реализация плеера с гарантированным отображением видео и "ВПЕРЁД"

import Foundation
import AVFoundation
import Combine
import SwiftUI

// MARK: - VideoPlayerViewModel

final class VideoPlayerViewModel: NSObject, ObservableObject {
    private let player: AVPlayer
    private var boundaryObserver: Any?
    private var playerItemContext = 0

    @Published var isFinished: Bool = false
    @Published var isPausedAtStop: Bool = false // Новый флаг паузы на остановке

    private var stopPoints: [CMTime] = []
    @Published var currentStopIndex: Int = 0
    var max: Int {
        get { stopPoints.count }
    }

    private var isReadyToPlay = false
    private var didLoadPoints = false

    private var playerItem: AVPlayerItem!

    override init() {
        guard let url = Bundle.main.url(forResource: "myVideo", withExtension: "mp4") else {
            fatalError("Не найдено mp4 в Bundle")
        }
        let item = AVPlayerItem(url: url)
        self.player = AVPlayer(playerItem: item)
        self.player.actionAtItemEnd = .pause
        self.player.rate = 0.0
        self.playerItem = item

        super.init()

        item.addObserver(self, forKeyPath: "status", options: [.new], context: &playerItemContext)
        generateStopPoints(for: item.asset)
    }

    deinit {
        player.currentItem?.removeObserver(self, forKeyPath: "status", context: &playerItemContext)
    }

    func isLast() -> Bool {
        currentStopIndex == stopPoints.count
    }
    
    func getPlayer() -> AVPlayer {
        return player
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard context == &playerItemContext,
              keyPath == "status",
              let item = object as? AVPlayerItem else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        if item.status == .readyToPlay {
            isReadyToPlay = true
            maybeStartPlayback()
        }
    }

    private func generateStopPoints(for asset: AVAsset) {
        
        asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
            guard let self = self else { return }
            var error: NSError?
            let status = asset.statusOfValue(forKey: "duration", error: &error)
            
            guard status == .loaded else {
                print("Ошибка загрузки длительности: \(error?.localizedDescription ?? "неизвестно")")
                return
            }
            
            let duration = asset.duration
            var points: [CMTime] = [
                CMTime(milliseconds: 500),
                CMTime(milliseconds: 890),
                CMTime(milliseconds: 1280),
                CMTime(milliseconds: 1600)
            ]

            let safeFinal = CMTimeSubtract(duration, CMTime(milliseconds: 10))
            if safeFinal > (points.last ?? .zero) {
                points.append(safeFinal)
            }

            DispatchQueue.main.async {
                self.stopPoints = points
                self.didLoadPoints = true
                self.maybeStartPlayback()
            }
        }
    }

    private func maybeStartPlayback() {
        guard isReadyToPlay, didLoadPoints, currentStopIndex == 0 else { return }
        startPlayback()
    }

    private func startPlayback() {
        guard currentStopIndex < stopPoints.count else { return }
        player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            self?.playUntilNextStop()
        }
    }

    private func addBoundaryObserver(for time: CMTime) {
        boundaryObserver = player.addBoundaryTimeObserver(
            forTimes: [NSValue(time: time)],
            queue: .main
        ) { [weak self] in
            guard let self = self else { return }
            self.player.pause()
            self.boundaryObserver = nil

            // Устанавливаем флаг, что мы на паузе в одной из точек
            self.isPausedAtStop = true

            if self.currentStopIndex >= self.stopPoints.count {
                self.isFinished = true
            }
        }
    }

    func playUntilNextStop() {
        guard currentStopIndex < stopPoints.count else { return }
        // Сбрасываем флаг паузы, видео сейчас пойдёт
        isPausedAtStop = false

        let nextTime = stopPoints[currentStopIndex]
        withAnimation {
            currentStopIndex += 1            
        }
        addBoundaryObserver(for: nextTime)
        player.rate = 0.5
    }
}

// MARK: - Кастомный UIView для AVPlayerLayer

class PlayerUIView: UIView {
    private(set) var playerLayer: AVPlayerLayer!

    init(player: AVPlayer) {
        super.init(frame: .zero)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

// MARK: - AVPlayerContainerView для SwiftUI

struct AVPlayerContainerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> UIView {
        return PlayerUIView(player: player)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // layoutSubviews обновит слой
    }
}

// MARK: - SwiftUI View

struct VideoOnboarding: View {
    @StateObject private var viewModel = VideoPlayerViewModel()

    @State var title: String = ""
    @State var text: String = ""
    
    @State var nextButtonColor: Color = .dirtyWhite
    @State var nextButtonText: String = "Next"
    @State var nextButtonWidth: CGFloat = 100.0
    @State var nextButtonIconColor: Color = .accentColor
    
    @Binding var onboardingComplete: Bool
    
    var body: some View {
        
        ZStack {

            AVPlayerContainerView(player: viewModel.getPlayer()).brightness(0.1)
            VStack {
                Spacer()
                VStack(alignment:.leading) {
                    Text(String(localized: .init(title)))
                        .font(.doto(.black, size: 40))
                        .contentTransition(.numericText())
                        .foregroundStyle(
                            LinearGradient(colors: [Color.introOne,Color.introTwo], startPoint: .leading, endPoint: .trailing)
                        )
                        
                    Text(String(localized: .init(text)))
                        .font(.system(size: 25, weight: .regular, design: .default))
                    HStack {
                        FillingProgressBar(
                            current: $viewModel.currentStopIndex,
                            max: viewModel.max
                        ).frame(width: 50)
                        Spacer()
                    
                        
                        Button {
                            if viewModel.currentStopIndex == 5 {
                                withAnimation {
                                    onboardingComplete = true
                                }
                            }
                            viewModel.playUntilNextStop()
                            
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .foregroundStyle(nextButtonColor)
                                Text(String(localized: .init(nextButtonText)))
                                    .bold()
                                    .foregroundStyle(nextButtonIconColor)
                                    .contentTransition(.numericText())
                            }
                            
                            .frame(width: nextButtonWidth, height: 40)
                        }
                        .allowsHitTesting(viewModel.isPausedAtStop)
                        
                    }
                }.padding(20)
            }
            .onChange(of: viewModel.currentStopIndex, {
                let i = viewModel.currentStopIndex - 1
                let max = viewModel.max-1
                let titles = [
                    "Capture",
                    "Simply",
                    "Adjust",
                    "Align",
                    "Overlay"
                ][i]
                
                let texts = [
                    "your loved ones’ portraits like a professional",
                    "choose your own reference or try the built-in ones",
                    "the overlay’s transparency to see your result",
                    "your shot with the reference—then snap the photo",
                    "any reference photo right in your camera view"
                ][i]
                
                withAnimation {
                    self.text = texts
                    self.title = titles
                    
                    if i == 0 {
                        nextButtonColor = .dirtyWhite
                        nextButtonIconColor = .accent
                    }
                    if i > 0 && i < max {
                        nextButtonColor = .accentColor
                        nextButtonWidth = 40
                        nextButtonText = ""
                        nextButtonIconColor = .white
                    }

                }

            })
        }.cornerRadius(40)
    }
}

// Расширение для создания CMTime из миллисекунд
extension CMTime {
    init(milliseconds: Int64) {
        self.init(value: milliseconds, timescale: 1000)
    }
}
