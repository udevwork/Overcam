//
//  DotoFont.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 26.05.2025.
//


import SwiftUI
import UIKit

/// 1) Выписать все имя-шрифты
enum DotoFont: String, CaseIterable {
    // Doto Rounded
    case roundedBlack       = "Doto_Rounded-Black"
    case roundedBold        = "Doto_Rounded-Bold"
    case roundedExtraBold   = "Doto_Rounded-ExtraBold"
    case roundedExtraLight  = "Doto_Rounded-ExtraLight"
    case roundedLight       = "Doto_Rounded-Light"
    case roundedMedium      = "Doto_Rounded-Medium"
    case roundedRegular     = "Doto_Rounded-Regular"
    case roundedSemiBold    = "Doto_Rounded-SemiBold"
    case roundedThin        = "Doto_Rounded-Thin"
    // Doto
    case black              = "Doto-Black"
    case bold               = "Doto-Bold"
    case extraBold          = "Doto-ExtraBold"
    case extraLight         = "Doto-ExtraLight"
    case light              = "Doto-Light"
    case medium             = "Doto-Medium"
    case regular            = "Doto-Regular"
    case semiBold           = "Doto-SemiBold"
    case thin               = "Doto-Thin"
}

/// 2) Расширение для создания Font.custom
extension Font {
    /// Простой вызов: Font.doto(.bold, size: 24)
    static func doto(_ font: DotoFont, size: CGFloat) -> Font {
        .custom(font.rawValue, size: size)
    }
    
    /// С учётом Dynamic Type: Font.doto(.regular, textStyle: .body)
    static func doto(_ font: DotoFont, textStyle: Font.TextStyle) -> Font {
        // Получаем размер шрифта из системных настроек
        let uiTextStyle = textStyle.toUIFontTextStyle()
        let pointSize = UIFont.preferredFont(forTextStyle: uiTextStyle).pointSize
        return .custom(font.rawValue, size: pointSize, relativeTo: textStyle)
    }
}

/// 3) Помощник для маппинга Font.TextStyle → UIFont.TextStyle
private extension Font.TextStyle {
    func toUIFontTextStyle() -> UIFont.TextStyle {
        switch self {
        case .largeTitle:   return .largeTitle
        case .title:        return .title1
        case .title2:       return .title2
        case .title3:       return .title3
        case .headline:     return .headline
        case .subheadline:  return .subheadline
        case .body:         return .body
        case .callout:      return .callout
        case .footnote:     return .footnote
        case .caption:      return .caption1
        case .caption2:     return .caption2
        @unknown default:   return .body
        }
    }
}
