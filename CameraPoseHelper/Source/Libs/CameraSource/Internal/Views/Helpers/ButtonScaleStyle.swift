//
//  ButtonScaleStyle.swift of MijickCameraView
//
//  Created by Tomasz Kurylik
//    - Twitter: https://twitter.com/tkurylik
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//
//  Copyright ©2024 Mijick. Licensed under MIT License.


import SwiftUI

struct ButtonScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { configuration
        .label
        .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}
