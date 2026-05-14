import SwiftUI

extension View {
    
    var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
    var adaptiveSpacing: CGFloat {
        if screenHeight < 700 { return 20 }
        if screenHeight < 740 { return 25 }
        return 40
    }
    
    var adaptivePaddingTop: CGFloat {
        if screenHeight < 700 { return 20 }
        if screenHeight < 740 { return 25 }
        return 75
    }
}
