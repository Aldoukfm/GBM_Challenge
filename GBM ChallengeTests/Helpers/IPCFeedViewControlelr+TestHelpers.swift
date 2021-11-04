
import XCTest
import UIKit
import GBMChallengeiOS

extension IPCFeedViewController {
    func simulateUserInitiatedReload() {
        refreshControl.simulatePullToRefresh()
    }
    
    var isUserInitiatedLoading: Bool {
        return refreshControl.isRefreshing
    }
    
    var isAutomaticLoading: Bool {
        guard let cell = cell(row: 0, section: 0) as? RefreshStatusCell else { return false }
        return cell.titleLbl.text == "Actualizando"
    }
    
    var numberOfCells: Int {
        (0..<collectionView.numberOfSections).reduce(0, { return $0 + self.collectionView.numberOfItems(inSection: $1) })
    }
    
    func numberOfCells(inSection section: Int) -> Int {
        collectionView.numberOfItems(inSection: section)
    }
    
    func chartCell() -> ChartCell? {
        return cell(row: 2, section: 0) as? ChartCell
    }
    
    func rangeCell() -> RangeControlCell? {
        cell(row: 3, section: 0) as? RangeControlCell
    }
    
    func cell(row: Int, section: Int) -> UICollectionViewCell? {
        let indexPath = IndexPath(row: row, section: section)
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return nil }
        return cellProvider(collectionView, indexPath, item)
    }
    
    func simulateRangeSelection(index: Int) throws {
        let rangeCell = try XCTUnwrap(rangeCell())
        rangeCell.collectionView.collectionView(rangeCell.collectionView, didSelectItemAt: IndexPath(row: index, section: 0))
    }
    
    public override func loadViewIfNeeded() {
        super.loadViewIfNeeded()
        collectionView.enforceLayoutCycle()
        collectionView.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        
    }
}
