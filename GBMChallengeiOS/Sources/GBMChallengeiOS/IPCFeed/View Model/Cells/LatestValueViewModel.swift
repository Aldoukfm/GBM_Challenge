
import UIKit

public struct LatestValueViewModel {
    let changeIcon: UIImage
    let changeColor: UIColor
    let price: String
    let change: String
    let date: String
}

extension LatestValueViewModel: Hashable {
    
}
