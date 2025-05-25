//
//  SliderStyle.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 29.08.2024.
//

import SwiftUI
import CompactSlider

public struct CustomCompactSliderStyle: CompactSliderStyle {
    
    enum Position {
       case top,middle,bottom,single
    }
    
    let position: Position
    
    public func makeBody(configuration: Configuration) -> some View {
        
        var size: (tL:CGFloat,tT:CGFloat,bL:CGFloat,bT:CGFloat) = (0,0,0,0)
        switch position {
            case .top:
                size = (20,20,2,2)
            case .middle:
                size = (2,2,2,2)
            case .bottom:
                size = (2,2,20,20)
            case .single:
                size = (20,20,20,20)
        }
        
       return configuration.label
            .foregroundColor(
                configuration.isHovering || configuration.isDragging ? Color.accent : .white
            )
            .background(
                .ultraThinMaterial
            )

            .clipShape(
                .rect(
                    topLeadingRadius: size.tL,
                    bottomLeadingRadius: size.bL,
                    bottomTrailingRadius: size.bT,
                    topTrailingRadius: size.tT
                )
            )
    }
}

public extension CompactSliderStyle where Self == CustomCompactSliderStyle {
    static var `top`: CustomCompactSliderStyle { CustomCompactSliderStyle(position: .top) }
    static var `middle`: CustomCompactSliderStyle { CustomCompactSliderStyle(position: .middle) }
    static var `bottom`: CustomCompactSliderStyle { CustomCompactSliderStyle(position: .bottom) }
    static var `single`: CustomCompactSliderStyle { CustomCompactSliderStyle(position: .single) }
}
