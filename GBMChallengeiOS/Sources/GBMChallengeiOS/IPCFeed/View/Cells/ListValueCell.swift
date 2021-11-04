
import UIKit

public class ListValueCell: UICollectionViewCell, ReuseIdentifiableView {
    
    private(set) public var priceLbl: UILabel! = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.font = Fonts.normalText
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private(set) public var changeLbl: UILabel! = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.font = Fonts.normalText
        lbl.setContentHuggingPriority(.defaultHigh, for: .vertical)
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private(set) public var changeImg: UIImageView! = {
        let img = UIImageView()
        img.contentMode = UIView.ContentMode.scaleAspectFit
        img.translatesAutoresizingMaskIntoConstraints = false
        return img
    }()
    
    private(set) public var dateLbl: UILabel! = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.font = Fonts.normalText
        lbl.numberOfLines = 2
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
        
        let changeStack = UIStackView(arrangedSubviews: [changeImg, changeLbl])
        changeStack.translatesAutoresizingMaskIntoConstraints = false
        changeStack.axis = .horizontal
        changeStack.alignment = .center
        changeStack.spacing = 2
        changeImg.constraintHeightTo(changeLbl, constant: -5)
        
        let changeContainer = UIView()
        changeContainer.translatesAutoresizingMaskIntoConstraints = false
        
        changeContainer.addSubview(changeStack)
        changeStack.constraintTo(changeContainer, attributes:  [.centerX, .centerY])
        
        changeStack.leftAnchor.constraint(greaterThanOrEqualTo: changeContainer.leftAnchor).isActive = true
        changeStack.rightAnchor.constraint(lessThanOrEqualTo: changeContainer.rightAnchor).isActive = true
        
        
        let container = UIStackView(arrangedSubviews: [
            priceLbl, changeContainer, dateLbl
        ])
        
        container.axis = .horizontal
        container.distribution = .equalSpacing
        container.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(container)
        container.constraintTo(self)
        
        priceLbl.constraintWidthTo(container, multiplier: 0.3)
        changeContainer.constraintWidthTo(container, multiplier: 0.4)
        dateLbl.constraintWidthTo(container, multiplier: 0.3)
        
        let height = contentView.heightAnchor.constraint(equalToConstant: 60)
        height.priority = .init(999)
        height.isActive = true
        
    }
    
    func bind(viewModel: ListValueViewModel) {
        priceLbl.text = viewModel.price
        changeLbl.text = viewModel.change
        changeLbl.textColor = viewModel.changeColor
        changeImg.image = viewModel.changeIcon
        dateLbl.text = viewModel.date
    }
}
