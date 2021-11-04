
import Foundation
import Combine

public class IPCFileStore: IPCStore {
    
    private struct Cache: Codable {
        let values: [CodableIPCValue]
        let timestamp: Date
    }
    
    private struct CodableIPCValue: Codable {
        public let date: Date
        public let price: Float
        public let percentageChange: Float
        public let volume: Int
        public let change: Float
    }
    
    private let storeURL: URL
    
    private let queue: DispatchQueue = DispatchQueue(label: "\(type(of: IPCFileStore.self))Queue", qos: .userInitiated, attributes: .concurrent)
    
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    public func fetch() -> AnyPublisher<CacheResult, Error> {
        let storeURL = self.storeURL
        return Future<CacheResult, Error> {[weak self] completion in
            guard let self = self else {
                completion(.failure(DeallocatedError()))
                return
            }
            self.queue.async {
                do {
                    let data = try Data(contentsOf: storeURL)
                    let decoder = JSONDecoder()
                    let cache = try decoder.decode(Cache.self, from: data)
                    let values = Self.map(codableValues: cache.values)
                    completion(.success((values, cache.timestamp)))
                } catch {
                    completion(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func insert(_ values: [IPCLocalValue], timestamp: Date) -> AnyPublisher<Void, Error> {
        let storeURL = self.storeURL
        return Future<Void, Error> {[weak self] completion in
            guard let self = self else {
                completion(.failure(DeallocatedError()))
                return
            }
            self.queue.async(flags: .barrier) {
                do {
                    let encoder = JSONEncoder()
                    let values = Self.map(values: values)
                    let cache = Cache(values: values, timestamp: timestamp)
                    let data = try encoder.encode(cache)
                    try data.write(to: storeURL)
                    completion(.success(()))
                } catch {
                    completion(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func delete() -> AnyPublisher<Void, Error> {
        let storeURL = self.storeURL
        return Future<Void, Error> {[weak self] completion in
            guard let self = self else {
                completion(.failure(DeallocatedError()))
                return
            }
            self.queue.async(flags: .barrier) {
                do {
                    try FileManager.default.removeItem(at: storeURL)
                    completion(.success(()))
                } catch let error as NSError where error.code == 4 {
                    completion(.success(()))
                } catch {
                    completion(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private struct DeallocatedError: Error { }
}

extension IPCFileStore {
    private static func map(values: [IPCLocalValue]) -> [CodableIPCValue] {
        return values.map { value in
            CodableIPCValue(date: value.date, price: value.price, percentageChange: value.percentageChange, volume: value.volume, change: value.change)
        }
    }
    
    private static func map(codableValues: [CodableIPCValue]) -> [IPCLocalValue] {
        return codableValues.map { value in
            IPCLocalValue(date: value.date, price: value.price, percentageChange: value.percentageChange, volume: value.volume, change: value.change)
        }
    }
}
