
import UIKit
import Combine
import CombineHelpers

public class LatestValueCell: UICollectionViewCell, ReuseIdentifiableView {
    
    private(set) public var priceLbl: UILabel! = {
        let lbl = UILabel()
        lbl.font = Fonts.headline
        lbl.textColor = Colors.primaryText
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private(set) public var changeImg: UIImageView! = {
        let img = UIImageView()
        img.contentMode = UIView.ContentMode.scaleAspectFit
        img.translatesAutoresizingMaskIntoConstraints = false
        return img
    }()
    
    private(set) public var changeLbl: UILabel! = {
        let lbl = UILabel()
        lbl.font = Fonts.normalText
        lbl.setContentHuggingPriority(.defaultHigh, for: .vertical)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private(set) public var dateLbl: UILabel! = {
        let lbl = UILabel()
        lbl.font = Fonts.normalText
        lbl.textColor = Colors.primaryText
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
        
        
        let changeContainer = UIStackView(arrangedSubviews: [changeImg, changeLbl])
        changeContainer.translatesAutoresizingMaskIntoConstraints = false
        changeContainer.axis = .horizontal
        changeContainer.alignment = .center
        changeContainer.spacing = 2
        changeImg.constraintHeightTo(changeLbl, constant: -5)
        
        let verticalStack = UIStackView(arrangedSubviews: [priceLbl, changeContainer, dateLbl])
        verticalStack.axis = .vertical
        verticalStack.alignment = .center
        verticalStack.spacing = 4
        verticalStack.setCustomSpacing(3, after: priceLbl)
        
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(verticalStack)
        verticalStack.constraintTo(contentView, attributes: [.left, .right, .centerY])
        
    }
    
    func bind(viewModel: LatestValueViewModel) {
        
        priceLbl.text = viewModel.price
        changeLbl.text = viewModel.change
        changeLbl.textColor = viewModel.changeColor
        changeImg.image = viewModel.changeIcon
        dateLbl.text = viewModel.date
        
    }
}
