
import Foundation
import Combine
import CombineHelpers

public class IPCRepository: IPCRepositoryType {
    
    private let cacheFetcher: IPCFetcher
    private let remoteFetcher: IPCFetcher
    private let cacheStore: IPCCache
    
    public init(cacheFetcher: IPCFetcher, remoteFetcher: IPCFetcher, cacheStore: IPCCache) {
        self.cacheFetcher = cacheFetcher
        self.remoteFetcher = remoteFetcher
        self.cacheStore = cacheStore
    }
    
    public func fetchValues() -> AnyPublisher<(IPCRepositorySource, [IPCValue]), Error> {
        
        let deallocatedFailure = Fail<[IPCValue], Error>(error: DeallocatedError()).eraseToAnyPublisher()
        
        let cachePublisher = Deferred {[weak self] in
            self?.cacheFetcher.fetchValues() ?? deallocatedFailure
        }
            .map({ values in
                return (IPCRepositorySource.cache, values)
            })
        
        
        let remotePublisher = Deferred {[weak self] in
            self?.remoteFetcher.fetchValues() ?? deallocatedFailure
        }
            .handleEvents(receiveOutput: {[weak self] values in
                self?.saveValuesIgnoringError(values)
            })
            .map({ values in
                return (IPCRepositorySource.remote, values)
            })
        
        return cachePublisher
            .optionalTry()
            .failable()
            .flatMap { result -> AnyPublisher<(IPCRepositorySource, [IPCValue]), Error> in
                if let result = result {
                    return Publishers.Merge(Just(result).failable(),  remotePublisher).eraseToAnyPublisher()
                } else {
                    return remotePublisher.eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    private func saveValuesIgnoringError(_ values: [IPCValue]) {
        cacheStore.saveValues(values).wait()
    }
    
    struct DeallocatedError: Error { }
}

