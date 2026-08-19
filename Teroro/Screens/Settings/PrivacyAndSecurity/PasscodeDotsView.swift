import SwiftUI

struct PasscodeDotsView: View {
    let filledCount: Int
    let totalCount: Int
    let color: Color

    var body: some View {
        HStack(spacing: 28) {
            ForEach(0..<totalCount, id: \.self) { index in
                Circle()
                    .fill(index < filledCount ? color : .clear)
                    .overlay {
                        Circle()
                            .stroke(color, lineWidth: 2)
                    }
                    .frame(width: 14, height: 14)
            }
        }
        .accessibilityLabel("\(filledCount) з \(totalCount) цифр введено")
    }
}
