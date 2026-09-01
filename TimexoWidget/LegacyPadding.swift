//
//  LegacyPadding.swift
//  Teroro
//
//  Created by Chmil Oleksandr on 31.08.26.
//



import SwiftUI

// MARK: - Padding only for iOS 16 and below

struct LegacyPadding: ViewModifier {
    let insets: EdgeInsets

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
        } else {
            content.padding(insets)
        }
    }
}

// MARK: - Convenience call syntax

extension View {

    /// Одинаковый паддинг со всех четырёх сторон.
    /// Пример: .legacyPadding(11)
    func legacyPadding(_ length: CGFloat) -> some View {
        modifier(LegacyPadding(insets: EdgeInsets(
            top: length, leading: length, bottom: length, trailing: length
        )))
    }

    /// Паддинг по выбранным edges (можно комбинировать через [.horizontal, .top] и т.д.)
    /// Пример: .legacyPadding(.horizontal, 11)
    func legacyPadding(_ edges: Edge.Set, _ length: CGFloat) -> some View {
        modifier(LegacyPadding(insets: EdgeInsets(
            top: edges.contains(.top) ? length : 0,
            leading: edges.contains(.leading) ? length : 0,
            bottom: edges.contains(.bottom) ? length : 0,
            trailing: edges.contains(.trailing) ? length : 0
        )))
    }

    /// Раздельно horizontal / vertical.
    /// Пример: .legacyPadding(horizontal: 11, vertical: 6)
    func legacyPadding(horizontal: CGFloat = 0, vertical: CGFloat = 0) -> some View {
        modifier(LegacyPadding(insets: EdgeInsets(
            top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal
        )))
    }

    /// Полностью раздельно по каждой стороне.
    /// Пример: .legacyPadding(top: 4, leading: 11, bottom: 8, trailing: 11)
    func legacyPadding(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) -> some View {
        modifier(LegacyPadding(insets: EdgeInsets(
            top: top, leading: leading, bottom: bottom, trailing: trailing
        )))
    }
}
