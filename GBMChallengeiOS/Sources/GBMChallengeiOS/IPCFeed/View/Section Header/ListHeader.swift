
import UIKit

class ListHeader: UICollectionReusableView, ReuseIdentifiableView {
    
    var priceLbl: UILabel! = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.font = Fonts.title2
        lbl.text = "Precio"
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    var changeLbl: UILabel! = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.font = Fonts.title2
        lbl.text = "Cambio"
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    var dateLbl: UILabel! = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.font = Fonts.title2
        lbl.text = "Fecha"
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func setupLayout() {
        let container = UIStackView(arrangedSubviews: [
            priceLbl, changeLbl, dateLbl
        ])
        container.backgroundColor = Colors.sectionHeaderBackground
        container.layer.cornerRadius = 8
        
        container.axis = .horizontal
        container.distribution = .equalSpacing
        container.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(container)
        container.constraintTo(self, insets: UIEdgeInsets(10, 0))
        
        priceLbl.constraintWidthTo(container, multiplier: 0.3)
        changeLbl.constraintWidthTo(container, multiplier: 0.4)
        dateLbl.constraintWidthTo(container, multiplier: 0.3)
        
    }
    
}
