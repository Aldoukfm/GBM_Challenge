
import Foundation
import Combine
import UIKit

public typealias CacheResult = (values: [IPCLocalValue], timestamp: Date)

public protocol IPCStore {
    func fetch() -> AnyPublisher<CacheResult, Error>
    func insert(_ values: [IPCLocalValue], timestamp: Date) -> AnyPublisher<Void, Error>
    func delete() -> AnyPublisher<Void, Error>
}

public class IPCLocalFetcher: IPCFetcher, IPCCache {
    
    private let store: IPCStore
    private let currentDate: () -> Date
    
    public init(store: IPCStore, currentDate: @escaping () -> Date = Date.init) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func fetchValues() -> AnyPublisher<[IPCValue], Swift.Error> {
        return store.fetch()
            .tryMap {[weak self] (values, timestamp) in
                guard let self = self else {
                    throw Error.deallocated
                }
                guard CachePolicy.validate(timestamp, against: self.currentDate()) else {
                    throw Error.expiredCache
                }
                return Self.map(localValues: values)
            }
            .eraseToAnyPublisher()
    }
    
    public func saveValues(_ values: [IPCValue]) -> AnyPublisher<Void, Swift.Error> {
        
        return store.delete()
            .flatMap {[weak self] _ -> AnyPublisher<Void, Swift.Error> in
                guard let self = self else { return Fail(error: Error.deallocated).eraseToAnyPublisher() }
                return self.store.insert(Self.map(modelValues: values), timestamp: self.currentDate())
            }
            .eraseToAnyPublisher()
        
    }
    
    enum Error: Swift.Error {
        case deallocated
        case expiredCache
    }
    
}

extension IPCLocalFetcher {
    private static func map(localValues: [IPCLocalValue]) -> [IPCValue] {
        return localValues.map { value in
            IPCValue(date: value.date, price: value.price, percentageChange: value.percentageChange, volume: value.volume, change: value.change)
        }
    }
    
    private static func map(modelValues: [IPCValue]) -> [IPCLocalValue] {
        return modelValues.map { value in
            IPCLocalValue(date: value.date, price: value.price, percentageChange: value.percentageChange, volume: value.volume, change: value.change)
        }
    }
}
