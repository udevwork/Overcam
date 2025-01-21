//
//  CameraInputBridgeView.swift of MijickCameraView
//
//  Created by Tomasz Kurylik
//    - Twitter: https://twitter.com/tkurylik
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//
//  Copyright ©2024 Mijick. Licensed under MIT License.


import SwiftUI

struct CameraInputBridgeView: UIViewRepresentable {
    let cameraManager: CameraManager
    private var inputView: UICameraInputView = .init()

    init(_ cameraManager: CameraManager) { self.cameraManager = cameraManager }
}
extension CameraInputBridgeView {
    func makeUIView(context: Context) -> some UIView {
        inputView.cameraManager = cameraManager
        return inputView.view
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
extension CameraInputBridgeView: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool { true }
}


// MARK: - UIViewController
fileprivate class UICameraInputView: UIViewController {
    var cameraManager: CameraManager!


    override func viewDidLoad() {
        super.viewDidLoad()

        setupCameraManager()
        setupTapGesture()
        setupPinchGesture()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        cameraManager.fixCameraRotation()
    }
}

// MARK: - Setup
private extension UICameraInputView {
    func setupCameraManager() {
        cameraManager.setup(in: view)
    }
    func setupTapGesture() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        view.addGestureRecognizer(tapRecognizer)
    }
    func setupPinchGesture() {
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture))
        view.addGestureRecognizer(pinchRecognizer)
    }
}

// MARK: - Gestures

// MARK: Tap
private extension UICameraInputView {
    @objc func handleTapGesture(_ tap: UITapGestureRecognizer) {
        let touchPoint = tap.location(in: view)
        setCameraFocus(touchPoint)
    }
}
private extension UICameraInputView {
    func setCameraFocus(_ touchPoint: CGPoint) {
        do { try cameraManager.setCameraFocus(touchPoint) }
        catch {}
    }
}

// MARK: Pinch
private extension UICameraInputView {
    @objc func handlePinchGesture(_ pinch: UIPinchGestureRecognizer) { if pinch.state == .changed {
        let desiredZoomFactor = cameraManager.attributes.zoomFactor + atan2(pinch.velocity, 33)
        changeZoomFactor(desiredZoomFactor)
    }}
}
private extension UICameraInputView {
    func changeZoomFactor(_ desiredZoomFactor: CGFloat) {
        do { try cameraManager.changeZoomFactor(desiredZoomFactor) }
        catch {}
    }
}
