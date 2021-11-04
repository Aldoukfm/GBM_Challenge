
import UIKit

class Fonts {
    
    static var normalText: UIFont {
        UIFont.systemFont(ofSize: 14, weight: .regular)
    }
    
    static var title1: UIFont {
        UIFont.systemFont(ofSize: 17, weight: .medium)
    }
    
    static var title2: UIFont {
        UIFont.systemFont(ofSize: normalText.pointSize, weight: .medium)
    }
    
    static var headline: UIFont {
        UIFont.systemFont(ofSize: 22, weight: .bold)
    }
}
