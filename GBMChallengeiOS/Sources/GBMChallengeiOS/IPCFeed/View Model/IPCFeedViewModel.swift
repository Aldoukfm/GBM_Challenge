
import UIKit
import Combine
import CombineHelpers
import GBMChallengeKit

public class IPCFeedViewModel {
    
    private let repository: IPCRepositoryType
    private let countdownCounter: Counter
    
    private let userInitiatedReload: CurrentValueSubject<Bool, Never>
    private let automaticReload: CurrentValueSubject<Bool, Never>
    
    private var data: CurrentValueSubject<(IPCRepositorySource, [IPCValue])?, Never>
    @Published private var dataSource: [(IPCFeedSection, [IPCFeedItem])] = []
    @Published private var timestampText: String? = ""
    @Published private var error: Error?
    
    private let refreshStatusViewModel: RefreshStatusViewModel
    private let rangeViewModel: RangeControlViewModel
    
    private var fetchCancellable: AnyCancellable?
    
    private var cancellables: [AnyCancellable] = []
    
    public init(repository: IPCRepositoryType, countdownCounter: Counter, rangeOptions: [RangeOption]) {
        
        self.repository = repository
        self.countdownCounter = countdownCounter
        

        self.userInitiatedReload = CurrentValueSubject<Bool, Never>(false)
        self.automaticReload = CurrentValueSubject<Bool, Never>(false)
        self.data = CurrentValueSubject(nil)
        
        self.refreshStatusViewModel = Self.makeRefreshStatusViewModel(userInitiatedLoadingPublisher: self.userInitiatedReload.eraseToAnyPublisher(), automaticLoadingPublisher: self.automaticReload.eraseToAnyPublisher(), countdownPublisher: countdownCounter.counter.eraseToAnyPublisher(), storeIn: &cancellables)
        
        let selectedIndexSubject = CurrentValueSubject<Int, Never>(0)
        
        self.rangeViewModel = Self.makeRangeControlViewModel(options: rangeOptions, selectedIndexSubject: selectedIndexSubject)
        
        setupReloadWhenStateChange(options: rangeOptions, selectedIndexPublisher: selectedIndexSubject.eraseToAnyPublisher(), dataPublisher: self.data.eraseToAnyPublisher())
        setupReloadWhenCounterReachZero(countdownPublisher: countdownCounter.counter)
    }
    
    private func setupReloadWhenStateChange(options: [RangeOption], selectedIndexPublisher: AnyPublisher<Int, Never>, dataPublisher: AnyPublisher<(IPCRepositorySource, [IPCValue])?, Never>) {
        Publishers.CombineLatest(selectedIndexPublisher, dataPublisher.unwrap())
            .sink {[unowned self] (selectedIndex, data) in
                let range: RangeOption = options.isEmpty ? .max : options[selectedIndex]
                handle(data: data, range: range)
            }
            .store(in: &cancellables)
    }
    
    private func handle(data: (source: IPCRepositorySource, values: [IPCValue]), range: RangeOption) {
        
        if data.source == .remote {
            updateTimestamptText()
        }
        
        let sortedValues: [IPCValue] = data.values.sorted(by: { $0.date > $1.date })

        var chartSectionItems: [IPCFeedItem] = []
        
        chartSectionItems.append(.refreshStatus(refreshStatusViewModel))
        
        if let latest = sortedValues.first {
            chartSectionItems.append(.latest(Self.makeLatestValueViewModel(latest)))
            let filteredValues = data.values.filter({ $0.date >= latest.date.addingTimeInterval(-range.toSeconds()) })
            chartSectionItems.append(.chart(Self.makeChartViewModel(filteredValues)))
        } else {
            chartSectionItems.append(.chart(Self.makeChartViewModel(data.values)))
        }

        chartSectionItems.append(.range(rangeViewModel))
        
        dataSource = [
            (.chart, chartSectionItems),
            (.list, sortedValues.map({ .value(Self.makeListValueViewModel($0)) }))
        ]
    }
    
    private func setupReloadWhenCounterReachZero(countdownPublisher: AnyPublisher<TimeInterval, Never>) {
        countdownPublisher
            .filter({ $0 == 0 })
            .sink(receiveValue: {[unowned self] _ in
                automaticReloadData()
            })
            .store(in: &cancellables)
    }

    private func automaticReloadData() {
        makeFetchRequest(updating: automaticReload, filter: { $0.0 == .remote })
    }
    
    private func makeFetchRequest(updating loadingSubject: CurrentValueSubject<Bool, Never>, filter: @escaping ((IPCRepositorySource, [IPCValue])) -> (Bool) = { _ in true }) {
        
        fetchCancellable?.cancel()
        countdownCounter.stop()
        
        loadingSubject.value = true
        fetchCancellable = repository
            .fetchValues()
            .dispatchOnMainQueue()
            .filter(filter)
            .sink(receiveCompletion: {[unowned self] completion in
                if case .failure = completion {
                    self.error = makeFetchingError()
                }
                loadingSubject.value = false
                countdownCounter.start()
            }, receiveValue: {[unowned self] result in
                data.value = result
            })
    }
    
    private func makeFetchingError() -> NSError {
        NSError(domain: "IPCFeedViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "No se pudo actualizar el IPC, intente más tarde"])
    }
    
    var title: String {
        return "Indice IPC"
    }
    
    var timestampTextPublisher: AnyPublisher<String?, Never> {
        $timestampText.eraseToAnyPublisher()
    }
    
    var userInitiatedLoadingPublisher: AnyPublisher<Bool, Never> {
        userInitiatedReload.eraseToAnyPublisher()
    }
    
    var dataSourcePublisher: AnyPublisher<[(IPCFeedSection, [IPCFeedItem])], Never> {
        return $dataSource.eraseToAnyPublisher()
    }
    
    var errorPublisher: AnyPublisher<Error, Never> {
        $error.unwrap().eraseToAnyPublisher()
    }
    
    func fetchData() {
        makeFetchRequest(updating: userInitiatedReload)
    }
    
    private func updateTimestamptText() {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:m"
        timestampText = "Ult. actualización Hoy " + formatter.string(from: Date())
    }
}


//MARK: - ViewModel factory methods

extension IPCFeedViewModel {
    
    private static func makeRefreshStatusViewModel(userInitiatedLoadingPublisher: AnyPublisher<Bool, Never>, automaticLoadingPublisher: AnyPublisher<Bool, Never>, countdownPublisher: AnyPublisher<TimeInterval, Never>, storeIn collection: inout [AnyCancellable]) -> RefreshStatusViewModel {
        
        func map(_ timeInterval: TimeInterval) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "mm:ss"
            let date = Date(timeIntervalSinceReferenceDate: timeInterval)
            return formatter.string(from: date)
        }
        
        let isLoadingPublisher: AnyPublisher<Bool, Never> = Publishers
            .CombineLatest(userInitiatedLoadingPublisher, automaticLoadingPublisher)
            .map { $0 || $1 }
            .eraseToAnyPublisher()
        
        let titleSubject = CurrentValueSubject<String?, Never>(nil)
        
        Publishers.Merge(
            isLoadingPublisher
                .map({ isLoading -> String? in
                    isLoading ? "Actualizando" : nil
                }),
            countdownPublisher
                .map({ timeInterval -> String? in
                    if timeInterval == 0 { return nil }
                    return "Siguiente actualización en " + map(timeInterval)
                })
        )
            .unwrap()
            .multicast(subject: titleSubject)
            .connect()
            .store(in: &collection)
        
        return RefreshStatusViewModel(titlePublisher: titleSubject.eraseToAnyPublisher())
    }
    
    private static func makeLatestValueViewModel(_ value: IPCValue) -> LatestValueViewModel {
        
        let icon: UIImage
        let changeColor: UIColor
        
        if value.change < 0 {
            changeColor = .systemRed
            icon = UIImage(systemName: "arrow.down", withConfiguration: UIImage.SymbolConfiguration(scale: .large))!.withTintColor(changeColor, renderingMode: .alwaysOriginal)
        } else {
            changeColor = .systemGreen
            icon = UIImage(systemName: "arrow.up", withConfiguration: UIImage.SymbolConfiguration(scale: .large))!.withTintColor(changeColor, renderingMode: .alwaysOriginal)
        }
        
        let price = String(format: "$ %.2f", arguments: [value.price])
        let change = String(format: "%.2f (%.2f%%)", arguments: [abs(value.change), abs(value.percentageChange)])
        
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy h:m:s.SS"
        let date = formatter.string(from: value.date)
        
        return LatestValueViewModel(changeIcon: icon, changeColor: changeColor, price: price, change: change, date: date)
    }
    
    private static func makeChartViewModel(_ values: [IPCValue]) -> ChartViewModel {
        
        let values = values.map({
            ChartValueViewModel(x: $0.date.timeIntervalSinceReferenceDate, y: Double($0.price))
        })
        
        return ChartViewModel(values: values)
    }
    
    private static func makeListValueViewModel(_ value: IPCValue) -> ListValueViewModel {
        let icon: UIImage
        let changeColor: UIColor
        
        if value.change < 0 {
            changeColor = .systemRed
            icon = UIImage(systemName: "arrow.down", withConfiguration: UIImage.SymbolConfiguration(scale: .large))!.withTintColor(changeColor, renderingMode: .alwaysOriginal)
        } else {
            changeColor = .systemGreen
            icon = UIImage(systemName: "arrow.up", withConfiguration: UIImage.SymbolConfiguration(scale: .large))!.withTintColor(changeColor, renderingMode: .alwaysOriginal)
        }
        
        let price = String(format: "$ %.2f", arguments: [value.price])
        let change = String(format: "%.2f (%.2f%%)", arguments: [abs(value.change), abs(value.percentageChange)])
        
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy h:m:s.SS"
        let date = formatter.string(from: value.date)
        
        return ListValueViewModel(id: value.date, changeIcon: icon, changeColor: changeColor, price: price, change: change, date: date)
    }
    
    private static func makeRangeControlViewModel(options: [RangeOption], selectedIndexSubject: CurrentValueSubject<Int, Never>) -> RangeControlViewModel {
        
        func map(option: RangeOption) -> String {
            switch option {
            case .minute(let t):
                return "\(t) min"
            case .hour(let t):
                return "\(t) hr"
            case .max:
                return "max"
            }
        }
        
        return RangeControlViewModel(options: options.map(map), selectedIndex: selectedIndexSubject)
        
    }
}
