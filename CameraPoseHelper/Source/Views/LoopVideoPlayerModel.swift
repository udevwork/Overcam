import Foundation
import AVFoundation

final class LoopVideoPlayerModel: ObservableObject {
    let player: AVQueuePlayer
    private var looper: AVPlayerLooper?

    init(_ filename: String) {
        // Загружаем видео из Bundle
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp4") else {
            fatalError("Не найдено \(filename).mp4 в Bundle")
        }
        let item = AVPlayerItem(url: url)
        
        // Используем AVQueuePlayer + AVPlayerLooper для бесконечного цикла
        player = AVQueuePlayer(playerItem: item)
        looper = AVPlayerLooper(player: player, templateItem: item)
        
        // Запускаем воспроизведение сразу
        player.play()
    }
    
    
    func getPlayer() -> AVPlayer {
        return player
    }
}
