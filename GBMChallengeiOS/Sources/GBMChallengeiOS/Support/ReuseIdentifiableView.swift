
import UIKit

protocol ReuseIdentifiableView: UICollectionReusableView {
    static var reuseID: String { get }
}

extension ReuseIdentifiableView {
    static var reuseID: String {
        "\(type(of: self))"
    }
}

extension UICollectionView {
    func reusableCell<Cell: ReuseIdentifiableView>(at indexPath: IndexPath) -> Cell {
        return dequeueReusableCell(withReuseIdentifier: Cell.reuseID, for: indexPath) as! Cell
    }
    
    func reusableSectionHeader<Header: ReuseIdentifiableView>(at indexPath: IndexPath) -> Header {
        return dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Header.reuseID, for: indexPath) as! Header
    }
    
    func register<View: ReuseIdentifiableView>(cell cellClass: View.Type) {
        register(View.self, forCellWithReuseIdentifier: View.reuseID)
    }
    
    func register<View: ReuseIdentifiableView>(header viewClass: View.Type) {
        register(View.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: View.reuseID)
    }
}
