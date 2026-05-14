import SwiftUI

struct Wave: Shape {
    var phase: Double
    var progress: Double
    
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let progressHeight = height * (1 - progress)
        let waveHeight: CGFloat = 10
        
        path.move(to: CGPoint(x: 0, y: progressHeight))
        
        for x in stride(from: 0, to: width, by: 1) {
            let relativeX = x / width
            let sine = sin(relativeX * .pi * 2 + phase)
            let y = progressHeight + CGFloat(sine) * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}
