
import UIKit
import Combine
import GBMChallengeKit


public protocol IPCFeedViewControllerDelegate: AnyObject {
    func ipcFeedViewController(_ viewController: IPCFeedViewController, didReceiveFetchingError error: Error)
}

public class IPCFeedViewController: UIViewController {
    
    private let viewModel: IPCFeedViewModel
    
    private(set) public lazy var refreshControl: UIRefreshControl! = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshHandler), for: .valueChanged)
        return refreshControl
    }()
    
    private(set) public var collectionView: UICollectionView! = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        cv.backgroundColor = .systemBackground
        cv.delaysContentTouches = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    public weak var delegate: IPCFeedViewControllerDelegate?
    
    private(set) public lazy var diffableDataSource = makeDataSource()
    
    private var cancellables: [AnyCancellable] = []
    
    public init(viewModel: IPCFeedViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        setupLayout()
        setupCollectionView()
        bind(viewModel: viewModel)
        viewModel.fetchData()
    }
    
    private func setupLayout() {
        view.addSubviews([collectionView])
        collectionView.constraintTo(view)
        
        collectionView.refreshControl = refreshControl
    }
    
    private func bind(viewModel: IPCFeedViewModel) {
        
        navigationItem.title = viewModel.title
        
        viewModel.userInitiatedLoadingPublisher
            .sink {[unowned self] isLoading in
                if isLoading {
                    refreshControl.beginRefreshing()
                } else {
                    refreshControl.endRefreshing()
                }
            }
            .store(in: &cancellables)
        
        viewModel.dataSourcePublisher
            .sink {[unowned self] (sections) in
                update(with: sections)
            }
            .store(in: &cancellables)
        
        viewModel.timestampTextPublisher
            .sink {[unowned self] text in
                navigationItem.prompt = text
            }
            .store(in: &cancellables)
        
        viewModel.errorPublisher
            .sink {[unowned self] error in
                display(error: error)
            }
            .store(in: &cancellables)
    }
    
    private func display(error: Error) {
        delegate?.ipcFeedViewController(self, didReceiveFetchingError: error)
    }
    
    @objc private func refreshHandler() {
        viewModel.fetchData()
    }
}

extension IPCFeedViewController {
    
    private func setupCollectionView() {
        collectionView.register(cell: RefreshStatusCell.self)
        collectionView.register(cell: LatestValueCell.self)
        collectionView.register(cell: ChartCell.self)
        collectionView.register(cell: RangeControlCell.self)
        
        collectionView.register(header: ListHeader.self)
        collectionView.register(cell: ListValueCell.self)
        
        collectionView.setCollectionViewLayout(makeCollectionLayout(), animated: false)
        collectionView.dataSource = diffableDataSource
    }
    
    private func update(with sections: [(section: IPCFeedSection, items: [IPCFeedItem])]) {
        
        var snapshot = NSDiffableDataSourceSnapshot<IPCFeedSection, IPCFeedItem>()
        
        snapshot.appendSections(sections.map { $0.section })
        for (section, items) in sections {
            snapshot.appendItems(items, toSection: section)
        }
        diffableDataSource.apply(snapshot, animatingDifferences: false)
    }
    
    public func cellProvider(_ collectionView: UICollectionView, _ indexPath: IndexPath, _ itemIdentifier: IPCFeedItem) -> UICollectionViewCell? {
        
        switch itemIdentifier {
        case .refreshStatus(let viewModel):
            let cell: RefreshStatusCell = collectionView.reusableCell(at: indexPath)
            cell.bind(viewModel: viewModel)
            return cell
            
        case .latest(let viewModel):
            let cell: LatestValueCell = collectionView.reusableCell(at: indexPath)
            cell.bind(viewModel: viewModel)
            return cell
            
        case .chart(let viewModel):
            let cell: ChartCell = collectionView.reusableCell(at: indexPath)
            cell.bind(viewModel: viewModel)
            return cell
            
        case .range(let viewModel):
            let cell: RangeControlCell = collectionView.reusableCell(at: indexPath)
            cell.bind(viewModel: viewModel)
            return cell
            
        case .value(let viewModel):
            let cell: ListValueCell = collectionView.reusableCell(at: indexPath)
            cell.bind(viewModel: viewModel)
            return cell
        }
        
    }
    
    private func makeDataSource() -> UICollectionViewDiffableDataSource<IPCFeedSection, IPCFeedItem> {
        let dataSource = UICollectionViewDiffableDataSource<IPCFeedSection, IPCFeedItem>.init(collectionView: collectionView) {[unowned self] collectionView, indexPath, itemIdentifier in
            cellProvider(collectionView, indexPath, itemIdentifier)
        }
        
        dataSource.supplementaryViewProvider = .init({ collectionView, elementKind, indexPath in
            
            switch elementKind {
            case UICollectionView.elementKindSectionHeader:
                let header: ListHeader = collectionView.reusableSectionHeader(at: indexPath)
                return header
            default:
                return nil
            }
        })
        
        return dataSource
    }
    
    private func makeCollectionLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { section, environment in
            switch section {
            case 0:
                let statusItem = NSCollectionLayoutItem(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50))
                let latestItem = NSCollectionLayoutItem(widthDimension: .fractionalWidth(1), heightDimension: .absolute(70))
                let chartItem = NSCollectionLayoutItem(widthDimension: .fractionalWidth(1), heightDimension: .absolute(250))
                let rangeItem = NSCollectionLayoutItem(widthDimension: .fractionalWidth(1), heightDimension: .absolute(45))
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(615))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [
                    statusItem,
                    latestItem,
                    chartItem,
                    rangeItem
                ])
                group.interItemSpacing = .fixed(25)
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = .init(top: 0, leading: 20, bottom: 50, trailing: 20)
                
                return section
                
            case 1:
                
                var config = UICollectionLayoutListConfiguration(appearance: .plain)
                config.headerMode = .supplementary
                config.headerTopPadding = 0
                
                var separatorConfig = UIListSeparatorConfiguration(listAppearance: .plain)
                separatorConfig.topSeparatorVisibility = .hidden
                separatorConfig.bottomSeparatorInsets = .zero
                config.separatorConfiguration = separatorConfig
                
                let listSection = NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)
                
                listSection.contentInsets = .init(top: 0, leading: 10, bottom: 30, trailing: 10)
                
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(33))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                listSection.boundarySupplementaryItems = [header]
                
                return listSection
            default:
                return nil
            }
        }
        
        
        return layout
    }
}

public extension NSCollectionLayoutItem {
    convenience init(widthDimension width: NSCollectionLayoutDimension, heightDimension height: NSCollectionLayoutDimension) {
        self.init(layoutSize: NSCollectionLayoutSize(widthDimension: width, heightDimension: height))
    }
}

import SwiftUI

struct IPCFeedProvider: PreviewProvider {
    
    static var previews: some View {
        VCContainer()
            .edgesIgnoringSafeArea(.all)
    }
    
    struct VCContainer: UIViewControllerRepresentable {
        typealias UIViewControllerType = IPCFeedViewController
        
        let repository = FakeRepository()
        let counter = FakeCounter()
        
        func makeUIViewController(context: Context) -> IPCFeedViewController {
            let viewModel = IPCFeedViewModel(repository: repository, countdownCounter: counter, rangeOptions: RangeOption.defaultOptions)
            return IPCFeedViewController(viewModel: viewModel)
        }
        
        func updateUIViewController(_ uiViewController: IPCFeedViewController, context: Context) {
            let vc = uiViewController
//            vc.view.enforceLayoutCycle()
            test_renderRemoteFromRepository(sut: vc)
        }
        
        func test_emptyInitialLoading() { }
        
        func test_renderCacheFromRepository(sut: IPCFeedViewController) {
            let values = makeTestValues()
            repository.fetchValuesSubject.send((.cache, values))
            
        }
        
        func test_renderRemoteFromRepository(sut: IPCFeedViewController) {
            let values = makeTestValues()
            repository.fetchValuesSubject.send((.remote, values))
            repository.fetchValuesSubject.send(completion: .finished)
            counter.counterSubject.send(60)
        }
        
        func makeTestValues() -> [IPCValue] {
            
            let url = Bundle.module.url(forResource: "TestIPCValues", withExtension: ".json")!
            let data = try! Data(contentsOf: url)
            
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSZZZZZ"
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            let values = try! decoder.decode([TestIPCValue].self, from: data).map({
                IPCValue(date: $0.date, price: $0.price, percentageChange: $0.percentageChange, volume: $0.volume, change: $0.change)
            })
            
            return values
        }
    }
    
    class FakeRepository: IPCRepositoryType {
        
        
        let fetchValuesSubject: PassthroughSubject<(IPCRepositorySource, [IPCValue]), Error> = PassthroughSubject()
        
        init() {
            
        }
        
        func fetchValues() -> AnyPublisher<(IPCRepositorySource, [IPCValue]), Error> {
            return fetchValuesSubject.eraseToAnyPublisher()
        }
    }
    
    class FakeCounter: Counter {
        
        let counterSubject: PassthroughSubject<TimeInterval, Never> = PassthroughSubject()
        
        var counter: AnyPublisher<TimeInterval, Never> {
            counterSubject.eraseToAnyPublisher()
        }
        
        func start() {
            
        }
        
        func stop() {
            
        }
    }
    
    struct TestIPCValue: Decodable {
        public let date: Date
        public let price: Float
        public let percentageChange: Float
        public let volume: Int
        public let change: Float
    }
}
