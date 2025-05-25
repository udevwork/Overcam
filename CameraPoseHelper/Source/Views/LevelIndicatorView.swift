import SwiftUI
import CoreMotion
import Combine

class LevelViewModel: ObservableObject {
    @Published var rollAngle: Double = 0
    @Published var isLevel: Bool = false
    
    private let motionManager = CMMotionManager()
    private var previousAngle: Double = 0
    private var isUpdating = false
    private let queue = OperationQueue()
    
    init() {
        queue.name = "com.yourapp.motionQueue"
        queue.qualityOfService = .background
    }
    
    // 👇 Публичный вызов
    func start() {
        guard !isUpdating, motionManager.isDeviceMotionAvailable else { return }
        isUpdating = true
        startMotionUpdates()
    }

    func stop() {
        guard isUpdating else { return }
        motionManager.stopDeviceMotionUpdates()
        isUpdating = false
    }

    private func startMotionUpdates() {
        motionManager.deviceMotionUpdateInterval = 0.3
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let self, let gravity = motion?.gravity else { return }

            let rawAngle = atan2(gravity.x, gravity.y) * 180 / .pi
            let targetAngle = rawAngle
            let smoothedAngle = self.smoothAngleChange(from: self.previousAngle, to: targetAngle)
            self.previousAngle = smoothedAngle

            let _tlevel = abs(smoothedAngle) < 178 || abs(smoothedAngle) > 182

            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.rollAngle = smoothedAngle
                    if self.isLevel != _tlevel {
                        self.isLevel = _tlevel
                        hapticLight()
                    }
                }
            }
        }
    }

    private func smoothAngleChange(from: Double, to: Double) -> Double {
        var delta = to - from
        if delta > 180 {
            delta -= 360
        } else if delta < -180 {
            delta += 360
        }
        return from + delta
    }

    deinit {
        stop()
    }
}


struct LevelIndicatorView: View {
    @ObservedObject var viewModel: LevelViewModel
    
    var body: some View {
        Image(systemName: "circle.and.line.horizontal")
            .opacity(viewModel.isLevel ? 1.0 : 0.3)
            .rotationEffect(Angle(degrees: viewModel.rollAngle))
            .shadow(radius: 5)
            .onAppear {
                viewModel.start()
            }
    }
}
