
import UIKit

extension UIView {
    
    func border() {
        layer.borderWidth = 1
        layer.borderColor = UIColor.black.cgColor
    }
    
    func borderSubviews() {
        for subview in subviews {
            subview.border()
            subview.borderSubviews()
        }
    }
}
