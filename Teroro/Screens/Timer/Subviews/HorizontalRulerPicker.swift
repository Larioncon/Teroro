import SwiftUI

struct HorizontalRulerPicker: View {
    @Binding var selection: Int
    private let values = Array(stride(from: 5, through: 120, by: 5))
    private let impact = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ZStack {
            // Visual Center Indicator
            Rectangle()
                .fill(Color.primary)
                .frame(width: 2, height: 60)
                .offset(y: 10)
                .zIndex(1)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 35) {
                        ForEach(values, id: \.self) { val in
                            GeometryReader { itemGeo in
                                let midX = itemGeo.frame(in: .global).midX
                                let screenMidX = UIScreen.main.bounds.width / 2
                                let distance = abs(midX - screenMidX)
                                
                                VStack(spacing: 12) {
                                    Text("\(val)")
                                        .font(.system(size: 22, weight: .bold))
                                        .scaleEffect(distance < 20 ? 1.2 : 1.0)
                                    
                                    Rectangle()
                                        .fill(distance < 20 ? Color.primary : Color.primary.opacity(0.2))
                                        .frame(width: 2, height: distance < 20 ? 45 : 30)
                                }
                                .foregroundStyle(distance < 20 ? Color.primary : Color.secondary)
                                .onChange(of: midX) { _ in
                                    if distance < 20 && selection != val {
                                        selection = val
                                        impact.impactOccurred()
                                    }
                                }
                            }
                            .frame(width: 40)
                            .id(val)
                        }
                    }
                    .padding(.horizontal, UIScreen.main.bounds.width / 2 - 20)
                }
                .frame(height: 100)
                .onAppear {
                    impact.prepare()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo(selection, anchor: .center)
                    }
                }
            }
        }
    }
}

#Preview {
    @State var selection = 25
    return HorizontalRulerPicker(selection: $selection)
}
