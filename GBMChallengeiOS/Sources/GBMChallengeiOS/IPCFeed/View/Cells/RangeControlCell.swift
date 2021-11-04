
import UIKit
import Combine

public class RangeControlCell: UICollectionViewCell, ReuseIdentifiableView {
    
    private(set) public var collectionView: TitleCollectionView! = {
        let cv = TitleCollectionView()
        cv.selectedColor = Colors.black
        cv.unselectedColor = Colors.unselectedText
        cv.selectedDecorationColor = Colors.selectedDecorationColor
        return cv
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
        contentView.addSubview(collectionView)
        collectionView.constraintTo(contentView)
    }
    
    func bind(viewModel: RangeControlViewModel) {
        
        collectionView.selectedIndex = viewModel.selectedIndex.value
        collectionView.update(viewModel.options, animated: false)
        
        collectionView.didSelectTitleAtIndex = { index in
            viewModel.selectedIndex.send(index)
        }
    }
}


public class TitleCell: UICollectionViewCell, ReuseIdentifiableView {
    
    private(set) public var titleLbl: UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = NSTextAlignment.center
        lbl.font = Fonts.normalText
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func setupLayout() {
        contentView.addSubview(titleLbl)
        titleLbl.constraintTo(contentView)
    }
}

struct TitleItem: Hashable {
    let title: String
    let isSelected: Bool
}

public class TitleCollectionView: UICollectionView {
    
    private var selectedDecorationView: UIView! = UIView()
    
    var selectedColor: UIColor = UIColor.label
    var unselectedColor: UIColor = UIColor.systemGray
    var selectedDecorationColor: UIColor = UIColor.systemGray {
        didSet {
            selectedDecorationView.backgroundColor = selectedDecorationColor
        }
    }
    
    var animationDuration: TimeInterval = 0.3
    private(set) var isAnimating: Bool = false
    
    var selectedIndex: Int?
    
    var didSelectTitleAtIndex: ((Int) -> ())?
    
    private lazy var diffableDataSource = makeDataSource()
    
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.minimumInteritemSpacing = 20
        
        super.init(frame: .zero, collectionViewLayout: layout)
        register(cell: TitleCell.self)
        delegate = self
        dataSource = diffableDataSource
        showsHorizontalScrollIndicator = false
        backgroundColor = UIColor.systemBackground
        translatesAutoresizingMaskIntoConstraints = false
        
        selectedDecorationView.backgroundColor = selectedDecorationColor
        addSubview(selectedDecorationView)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func update(_ titles: [String], animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, TitleItem>()
        snapshot.appendSections([0])
        let items = titles.enumerated().map { TitleItem(title: $0.element, isSelected: $0.offset == self.selectedIndex) }
        snapshot.appendItems(items, toSection: 0)
        diffableDataSource.apply(snapshot, animatingDifferences: animated, completion: nil)
    }
    
    private func makeDataSource() -> UICollectionViewDiffableDataSource<Int, TitleItem> {
        UICollectionViewDiffableDataSource<Int, TitleItem>(collectionView: self) {[unowned self] (collectionView, indexPath, item) -> UICollectionViewCell? in
            
            let cell: TitleCell = collectionView.reusableCell(at: indexPath)
            
            cell.titleLbl.textColor = item.isSelected ? self.selectedColor : self.unselectedColor
            cell.titleLbl.text = item.title
            
            //Initial mask
            if item.isSelected, (selectedDecorationView.layer.mask as? CAShapeLayer) == nil {
                self.setSelectedDecorationViewOn(cellFrame: cell.frame, animated: false)
            }
            
            return cell
        }
    }
}

extension TitleCollectionView: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let sectionTitle = diffableDataSource.snapshot().itemIdentifiers[indexPath.row].title
        let sectionTitleSize = sectionTitle.sizeToFit(font: TitleCell().titleLbl.font)
        
        let height: CGFloat = collectionView.frame.height - (collectionView.contentInset.top + collectionView.contentInset.bottom)
        let width: CGFloat = sectionTitleSize.width + 32
        
        return CGSize(width: width, height: height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let availableWidth = frame.width - (contentInset.left + contentInset.right)
        let numberOfCells = diffableDataSource.snapshot().itemIdentifiers.count
        let contentWidth = (0..<numberOfCells).reduce(CGFloat(0)) { partialResult, row in
            return partialResult + self.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: IndexPath(row: row, section: 0)).width
        }
        
        return (availableWidth - contentWidth) / CGFloat(numberOfCells - 1)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectTitle(at: indexPath.row)
        didSelectTitleAtIndex?(indexPath.row)
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        sendSubviewToBack(selectedDecorationView)
    }
    
    func selectTitle(at index: Int) {
        guard let cellFrame = collectionViewLayout.layoutAttributesForItem(at: IndexPath(row: index, section: 0))?.frame else { return }
        
        var xOffset: CGFloat = 0
        
        //Is offseted to the left
        if cellFrame.origin.x - contentOffset.x < contentInset.left {
            xOffset = (cellFrame.origin.x - contentOffset.x) - contentInset.left
        }
        
        //Is offseted to the right
        if cellFrame.maxX - contentOffset.x > frame.width - contentInset.right {
            xOffset = (cellFrame.maxX - contentOffset.x) - (frame.width - contentInset.right)
        }
        
        //Is offseted
        if xOffset != 0 {
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut) {
                self.contentOffset.x += xOffset
            }
        }
        
        guard selectedIndex != index else { return }
        selectedIndex = index
        update(diffableDataSource.snapshot().itemIdentifiers.map({ $0.title }), animated: true)
        setSelectedDecorationViewOn(cellFrame: cellFrame)
    }
    
    func setSelectedDecorationViewOn(cellFrame: CGRect, animated: Bool = true) {
        
        let frame = cellFrame
        
        guard let sourceMask = selectedDecorationView.layer.mask as? CAShapeLayer, animated else {
            selectedDecorationView.layer.mask = selectedDecorationViewRoundedMask(for: frame)
            selectedDecorationView.frame = frame
            return
        }
        
        isAnimating = true
        
        UIView.animate(withDuration: animationDuration, delay: 0.0, options: .curveEaseOut, animations: {
            self.selectedDecorationView.frame = frame
        }, completion: { (_) in
            self.isAnimating = false
        })
        
        let destinationMask = selectedDecorationViewRoundedMask(for: frame)
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationDuration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut))
        CATransaction.setDisableActions(true)
        
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = sourceMask.path
        pathAnimation.toValue = destinationMask.path
        sourceMask.path = destinationMask.path
        sourceMask.add(pathAnimation, forKey: "roundedPathAnimation")
        
        CATransaction.commit()
        
    }
    
    func selectedDecorationViewRoundedMask(for frame: CGRect) -> CAShapeLayer {
        
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: frame.width, height: frame.height), cornerRadius: 8)
        
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        
        return mask
    }
}
