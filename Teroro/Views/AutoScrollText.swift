import EFAutoScrollLabel
import SwiftUI
import UIKit

struct AutoScrollText: UIViewRepresentable {
    var text: String
    var font: UIFont = .preferredFont(forTextStyle: .body)
    var textColor: UIColor = .label
    var scrollSpeed: CGFloat = 30
    var pauseInterval: TimeInterval = 1.7
    var labelSpacing: CGFloat = 30
    var fadeLength: CGFloat = 12
    var scrollDirection: EFAutoScrollDirection = .left
    var textAlignment: NSTextAlignment = .left

    func makeUIView(context: Context) -> EFAutoScrollLabel {
        let label = EFAutoScrollLabel()
        label.backgroundColor = .clear
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        updateLabelProperties(label)
        return label
    }

    func updateUIView(_ uiView: EFAutoScrollLabel, context: Context) {
        updateLabelProperties(uiView)
        uiView.scrollLabelIfNeeded()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: EFAutoScrollLabel, context: Context) -> CGSize? {
        let width = proposal.width ?? UIView.noIntrinsicMetric
        let height = ceil(font.lineHeight)
        return CGSize(width: width, height: height)
    }

    private func updateLabelProperties(_ label: EFAutoScrollLabel) {
        if label.text != text {
            label.text = text
        }
        if label.font != font {
            label.font = font
        }
        if label.textColor != textColor {
            label.textColor = textColor
        }
        if label.scrollSpeed != scrollSpeed {
            label.scrollSpeed = scrollSpeed
        }
        if label.pauseInterval != pauseInterval {
            label.pauseInterval = pauseInterval
        }
        if label.labelSpacing != labelSpacing {
            label.labelSpacing = labelSpacing
        }
        if label.fadeLength != fadeLength {
            label.fadeLength = fadeLength
        }
        if label.scrollDirection != scrollDirection {
            label.scrollDirection = scrollDirection
        }
        if label.textAlignment != textAlignment {
            label.textAlignment = textAlignment
        }
    }
}
