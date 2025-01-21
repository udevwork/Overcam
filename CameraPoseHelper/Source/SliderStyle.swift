//
//  SliderStyle.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 29.08.2024.
//

import SwiftUI
import CompactSlider

public struct CustomCompactSliderStyle: CompactSliderStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(
                configuration.isHovering || configuration.isDragging ? Color.accent : .white
            )
            .background(
                .ultraThinMaterial
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

public extension CompactSliderStyle where Self == CustomCompactSliderStyle {
    static var `custom`: CustomCompactSliderStyle { CustomCompactSliderStyle() }
}
