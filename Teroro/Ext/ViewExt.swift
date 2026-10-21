import SwiftUI

extension View {
    
    var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }

    var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
    var isSmallScreen: Bool {
        screenHeight < 700
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

    var adaptivePaddingTopPW: CGFloat {
        if screenHeight < 700 { return 20 }
        if screenHeight < 740 { return 25 }
        return 0
    }
    


    func logScreenSizeOnAppear() -> some View {
        self.onAppear {
            UIScreen.printScreenSize()
        }
    }
}

extension UIScreen {
    static func printScreenSize() {
        let bounds = UIScreen.main.bounds
        print("📱🚨💥 [Screen Size] 🀹 Width: \(bounds.width), 🁫 Height: \(bounds.height)")
    }
}
