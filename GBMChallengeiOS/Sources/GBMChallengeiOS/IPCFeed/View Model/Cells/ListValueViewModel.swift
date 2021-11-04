
import UIKit

public struct ListValueViewModel {
    let id: Date
    let changeIcon: UIImage
    let changeColor: UIColor
    let price: String
    let change: String
    let date: String
}

extension ListValueViewModel: Hashable {
    public static func ==(lhs: ListValueViewModel, rhs: ListValueViewModel) -> Bool {
        return lhs.id == rhs.id
    }
}
