import SwiftUI
import MapKit

struct MapTypeButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isSelected ? Color.accentColor : .primary)
                .frame(width: 44, height: 44)
                .glassBackground(Circle(), fill: .regularMaterial, withGradient: false)
                .overlay(
                    Circle()
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}
