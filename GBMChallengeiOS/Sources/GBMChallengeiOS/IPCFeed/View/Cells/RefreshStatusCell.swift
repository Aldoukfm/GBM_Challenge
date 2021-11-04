
import UIKit
import Combine
import CombineHelpers
import ConstraintHelpers

public class RefreshStatusCell: UICollectionViewCell, ReuseIdentifiableView {
    
    private(set) public var titleLbl: UILabel! = {
        let lbl = UILabel()
        lbl.textAlignment = NSTextAlignment.center
        lbl.textColor = Colors.secondaryText
        lbl.font = Fonts.normalText
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private var cancellables: [AnyCancellable] = []
    
    private func setupLayout() {
        contentView.addSubview(titleLbl)
        titleLbl.constraintTo(contentView)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bind(viewModel: RefreshStatusViewModel) {
        cancellables.forEach { $0.cancel() }
        viewModel
            .titlePublisher
            .weakAssign(to: \UILabel.text, on: titleLbl)
            .store(in: &cancellables)
    }
}
