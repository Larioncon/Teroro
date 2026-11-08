import SwiftUI

public struct DuoAdaptiveLayout<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ContentBuilder private let content: (_ isDuo: Bool, _ isTrailingBar: Bool) -> Content

    public init(@ContentBuilder content: @escaping (_ isDuo: Bool, _ isTrailingBar: Bool) -> Content) {
        self.content = content
    }

    public var body: some View {
        if #available(iOS 27.1, *) {
            DuoToolbarVerticalEdgeReader(isCompactDuoByScene: isCompactDuo) { isDuo, isTrailingBar in
                content(isDuo, isTrailingBar)
            }
        } else {
            content(isCompactDuo, isCompactDuo)
        }
    }

    /// Проверяем, что экран находится в компактном режиме Duo (внешний дисплей)
    private var isCompactDuo: Bool {
        guard horizontalSizeClass == .compact else { return false }
        return Self.isDuoWindowScene
    }

    /// Определение геометрии сцены активного окна (без устаревшего UIScreen.main)
    fileprivate static var isDuoWindowScene: Bool {
        let idiom = UIDevice.current.userInterfaceIdiom
        guard idiom == .phone else { return false }

        let windowSize: CGSize = {
            if let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows)
                .first(where: \.isKeyWindow) {
                return window.bounds.size
            }
            return UIScreen.main.bounds.size
        }()

        guard windowSize.width > 0, windowSize.height > 0 else { return false }
        let ratio = max(windowSize.width, windowSize.height) / min(windowSize.width, windowSize.height)
        return ratio < 1.6
    }
}

@available(iOS 27.1, *)
private struct DuoToolbarVerticalEdgeReader<Content: View>: View {
    @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge
    let isCompactDuoByScene: Bool
    @ContentBuilder let content: (_ isDuo: Bool, _ isTrailingBar: Bool) -> Content

    var body: some View {
        let isDuo = (toolbarVerticalEdge != nil) || isCompactDuoByScene
        let isTrailingBar = (toolbarVerticalEdge == .trailing) || (isCompactDuoByScene && toolbarVerticalEdge == nil)
        content(isDuo, isTrailingBar)
    }
}


//
//import SwiftUI
//
//public struct DuoAdaptiveLayout<Content: View>: View {
//    @ViewBuilder private let content: (_ isDuo: Bool, _ isTrailingBar: Bool) -> Content
//
//    public init(@ViewBuilder content: @escaping (_ isDuo: Bool, _ isTrailingBar: Bool) -> Content) {
//        self.content = content
//    }
//
//    public var body: some View {
//        if #available(iOS 27.1, *) {
//            DuoToolbarVerticalEdgeReader { isDuo, isTrailingBar in
//                content(isDuo, isTrailingBar)
//            }
//        } else {
//            let isDuo = DuoLayoutDetector.isIPhoneDuo
//            content(isDuo, isDuo)
//        }
//    }
//}
//
//@available(iOS 27.1, *)
//private struct DuoToolbarVerticalEdgeReader<Content: View>: View {
//    @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge
//    @ViewBuilder let content: (_ isDuo: Bool, _ isTrailingBar: Bool) -> Content
//
//    var body: some View {
//        let isDuoByRatio = DuoLayoutDetector.isIPhoneDuo
//        let isDuo = (toolbarVerticalEdge != nil) || isDuoByRatio
//        let isTrailingBar = (toolbarVerticalEdge == .trailing) || (isDuoByRatio && toolbarVerticalEdge == nil)
//        content(isDuo, isTrailingBar)
//    }
//}
//
//public enum DuoLayoutDetector {
//    public static var isIPhoneDuo: Bool {
//        let idiom = UIDevice.current.userInterfaceIdiom
//        guard idiom == .phone else { return false }
//        let bounds = UIScreen.main.bounds
//        let ratio = max(bounds.width, bounds.height) / max(min(bounds.width, bounds.height), 1)
//        return ratio < 1.6
//    }
//}
