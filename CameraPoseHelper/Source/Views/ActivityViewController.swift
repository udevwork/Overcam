//
//  ActivityViewController.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 26.05.2025.
//


import SwiftUI
import UIKit
import Foundation

struct ShareView: UIViewControllerRepresentable {

    let items: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(
            activityItems: items,
            applicationActivities: applicationActivities
        )
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    
    }
}
