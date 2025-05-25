//
//  haptic.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 30.04.2025.
//


import UIKit

func haptic(_ notificationType: UINotificationFeedbackGenerator.FeedbackType = .warning){
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.warning)
}

func hapticLight(){
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()
}
