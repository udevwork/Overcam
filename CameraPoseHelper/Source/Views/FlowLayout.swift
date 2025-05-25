//
//  FlowLayout.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 24.05.2025.
//

import SwiftUI

struct TextEmoji: Codable, Equatable {
    var id: String = UUID().uuidString
    var text: String
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }

}


struct FlowLayout<Content: View>: View {
    var items: [TextEmoji]
    let spacing: CGFloat
    let content: (TextEmoji) -> Content
    var addEditButton: Bool = false

    @State private var totalHeight: CGFloat = .zero

    init(items: [TextEmoji], spacing: CGFloat = 10, @ViewBuilder content: @escaping (TextEmoji) -> Content) {
        self.items = items
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        VStack {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight) // Высота подстраивается под контент
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width: CGFloat = 0
        var height: CGFloat = 0

        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.id) { item in
                self.content(item)
                   
                    .alignmentGuide(.leading, computeValue: { d in
                        if abs(width - d.width) > geometry.size.width {
                            width = 0 // Переход на следующую строку
                            height -= d.height + self.spacing
                        }
                        let result = width
                        if item == self.items.last {
                            width = 0 // Сброс ширины
                        } else {
                            width -= d.width + self.spacing
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { _ in
                        let result = height
                        if item == self.items.last {
                            height = 0 // Сброс высоты
                        }
                        return result
                    })
            }
        }
        .background(viewHeightReader($totalHeight)) // Вычисление общей высоты
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry -> Color in
            DispatchQueue.main.async {
                binding.wrappedValue = geometry.size.height
            }
            return Color.clear
        }
    }
}
