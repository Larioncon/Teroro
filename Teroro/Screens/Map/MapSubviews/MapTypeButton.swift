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
                .background(.regularMaterial, in: Circle())
                .overlay(
                    Circle()
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
