//
//  GridOverlay.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 02.05.2025.
//
import SwiftUI

struct GridOverlay: View {
    
    @Binding var showGrid: Bool
    
    let rows: Int = 3
    let columns: Int = 3
    let color: Color = .white.opacity(0.2)

    var body: some View {
        if showGrid {
            GeometryReader { geo in
                Path { path in
                    let w = geo.size.width
                    let h = geo.size.height
                    
                    // Вертикальные линии
                    for i in 1..<columns {
                        let x = w / CGFloat(columns) * CGFloat(i)
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: h))
                    }
                    
                    // Горизонтальные линии
                    for i in 1..<rows {
                        let y = h / CGFloat(rows) * CGFloat(i)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: w, y: y))
                    }
                }
                .stroke(color, lineWidth: 1)
            }
            .allowsHitTesting(false)
        }
    }
}
