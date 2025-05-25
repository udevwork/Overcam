//
//  FillingProgressBar.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 10.05.2025.
//
import SwiftUI
import Foundation

struct FillingProgressBar: View {
    @Binding var current: Int
    var max: Int

    private var fraction: CGFloat {
        guard max > 0 else { return 0 }
        // Ограничиваем от 0 до 1
        return min(Swift.max(CGFloat(current) / CGFloat(max), 0), 1)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Фон — серая линия
                Capsule()
                    .fill(Color.gray)
                    .frame(height: 8)
                // Заполненная часть — белая линия
                Capsule()
                    .fill(Color.white)
                    .frame(
                        width: geo.size.width * fraction,
                        height: 8
                    )
            }
        }
        .frame(height: 10) // фиксированная высота 10pt
    }
}
