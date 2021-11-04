
import XCTest
import TestHelpers
import Combine
import GBMChallengeKit

class IPCRepositoryTests: XCTestCase {
    
    
    func test_fetchValues_doesNotFailOnCacheError() {
        let collaborators = makeSut()
        let sut = collaborators.sut
        
        let spy = PublisherSpy(sut.fetchValues())
        
        collaborators.cache.complete(with: .failure(makeAnyError()))
        
        XCTAssertNil(spy.error)
    }
    
    func test_fetchValues_failOnCacheAndRemoteError() {
        let collaborators = makeSut()
        let sut = collaborators.sut
        
        let spy = PublisherSpy(sut.fetchValues())
        
        collaborators.cache.complete(with: .failure(makeAnyError()))
        collaborators.remote.complete(with: .failure(makeAnyError()))
        
        XCTAssertNotNil(spy.error)
    }
    
    func test_fetchValues_requestsCacheBeforeRemote() {
        let collaborators = makeSut()
        let sut = collaborators.sut
        
        let _ = PublisherSpy(sut.fetchValues())
        
        XCTAssertEqual(collaborators.cache.fetchValuesCallCount, 1)
        XCTAssertEqual(collaborators.remote.fetchValuesCallCount, 0)
    }
    
    func test_fetchValues_requestsRemoteWhenCacheCompletes() {
        let collaborators = makeSut()
        let sut = collaborators.sut
        
        let _ = PublisherSpy(sut.fetchValues())
        collaborators.cache.complete(with: .failure(makeAnyError()))
        
        XCTAssertEqual(collaborators.remote.fetchValuesCallCount, 1)
    }
    
    func test_fetchValues_deliversCacheThenRemoteValues() {
        let collaborators = makeSut()
        let sut = collaborators.sut
        
        let spy = PublisherSpy(sut.fetchValues())
        let expectedCacheValues = makeUniqueValues()
        collaborators.cache.complete(with: .success(expectedCacheValues))
        
        let expectedRemoteValues = makeUniqueValues()
        collaborators.remote.complete(with: .success(expectedRemoteValues))
        
        XCTAssertEqual(spy.values.map({ $0.0 }), [.cache, .remote])
        XCTAssertEqual(spy.values.map({ $0.1 }), [expectedCacheValues, expectedRemoteValues])
    }
    
    func test_fetchValues_deliversRemoteValuesWhenCacheFails() {
        let collaborators = makeSut()
        let sut = collaborators.sut
        
        let spy = PublisherSpy(sut.fetchValues())
        collaborators.cache.complete(with: .failure(makeAnyError()))
        
        let expectedRemoteValues = makeUniqueValues()
        collaborators.remote.complete(with: .success(expectedRemoteValues))
        
        XCTAssertEqual(spy.values.map({ $0.0 }), [.remote])
        XCTAssertEqual(spy.values.map({ $0.1 }), [expectedRemoteValues])
    }
    
    func test_fetchValues_saveValuesFromRemote() {
        let collaborators = makeSut()
        let sut = collaborators.sut
        
        let _ = PublisherSpy(sut.fetchValues())
        
        collaborators.cache.complete(with: .failure(makeAnyError()))
        
        let expectedRemoteValues = makeUniqueValues()
        collaborators.remote.complete(with: .success(expectedRemoteValues))
        
        XCTAssertEqual(collaborators.cacheStore.values, expectedRemoteValues)
    }
    
    //MARK: - Helpers
    
    func makeSut(file: StaticString = #filePath, line: UInt = #line) -> (sut: IPCRepository, cache: IPCFetcherSpy, remote: IPCFetcherSpy, cacheStore: InMemoryCacheSpy) {
        let cache = IPCFetcherSpy()
        let remote = IPCFetcherSpy()
        let cacheStore = InMemoryCacheSpy()
        let sut = IPCRepository(cacheFetcher: cache, remoteFetcher: remote, cacheStore: cacheStore)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(cache, file: file, line: line)
        trackForMemoryLeaks(remote, file: file, line: line)
        trackForMemoryLeaks(cacheStore, file: file, line: line)
        
        return (sut, cache, remote, cacheStore)
    }
    
    func makeUniqueValues(for dates: [Date]) -> [IPCValue] {
        return dates.map({
            IPCValue(
                date: $0,
                price: Float.random(in: 1...1000),
                percentageChange: Float.random(in: -1...1),
                volume: Int.random(in: 1...1000),
                change: Float.random(in: -1000...1000))
        })
    }
    
    class InMemoryCacheSpy: IPCCache {
        
        private(set) var values: [IPCValue]
        
        init(_ stub: [IPCValue] = []) {
            self.values = stub
        }
        
        func saveValues(_ values: [IPCValue]) -> AnyPublisher<Void, Error> {
            self.values = values
            return Just(()).failable().eraseToAnyPublisher()
        }
    }
    
    class IPCFetcherSpy: IPCFetcher {
        
        typealias Result = Swift.Result<[IPCValue], Error>
        
        private var subjects: [PassthroughSubject<[IPCValue], Error>] = []
        
        private(set) var fetchValuesCallCount: Int = 0
        
        func complete(with result: Result, at index: Int = 0) {
            switch result {
            case .success(let values):
                subjects[index].send(values)
                subjects[index].send(completion: .finished)
            case .failure(let error):
                subjects[index].send(completion: .failure(error))
            }
        }
        
        func fetchValues() -> AnyPublisher<[IPCValue], Error> {
            fetchValuesCallCount += 1
            let subject: PassthroughSubject<[IPCValue], Error> = PassthroughSubject()
            subjects.append(subject)
            return subject.eraseToAnyPublisher()
        }
    }
    
}



