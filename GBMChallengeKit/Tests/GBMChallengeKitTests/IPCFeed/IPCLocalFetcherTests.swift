
import XCTest
import GBMChallengeKit
import TestHelpers
import Combine


class IPCLocalFetcherTests: XCTestCase {

    
    //MARK: - fetchValues
    
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssert(store.receivedMessages.isEmpty)
    }
    
    func test_fetchValues_requestFetch() {
        let (sut, store) = makeSUT()
        
        _ = PublisherSpy(sut.fetchValues())
        
        XCTAssertEqual(store.receivedMessages, [.fetch])
    }
    
    func test_fetchValues_failsOnFetchError() {
        let (sut, store) = makeSUT()
        
        let spy = PublisherSpy(sut.fetchValues())
        
        let expectedError = makeAnyError()
        store.completeFetch(with: expectedError)
        
        let error = spy.error as NSError?
        XCTAssertEqual(error, expectedError)
    }
    
    func test_fetchValues_deliversEmptyArrayOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        let spy = PublisherSpy(sut.fetchValues())
        
        let expectedResult = ([IPCLocalValue](), makeNonExpiredDate())
        
        store.completeFetch(with: expectedResult)
        
        XCTAssertEqual(spy.values, [[]])
    }
    
    func test_fetchValues_deliversCachedValuesOnNonExpiredCache() {
        let (sut, store) = makeSUT()
        
        let spy = PublisherSpy(sut.fetchValues())
        
        let testData = makeTestValues()
        
        let cacheResult = (testData.local, makeNonExpiredDate())
        store.completeFetch(with: cacheResult)
        
        XCTAssertEqual(spy.values, [testData.model])
    }
    
    func test_fetchValues_failsOnExpiredCache() {
        let (sut, store) = makeSUT()
        
        let spy = PublisherSpy(sut.fetchValues())
        
        let testData = makeTestValues()
        
        let cacheResult = (testData.local, makeExpiredDate())
        store.completeFetch(with: cacheResult)
        
        XCTAssertNotNil(spy.error)
    }
    
    //MARK: saveValues
    
    func test_saveValues_requestDeletion() {
        let (sut, store) = makeSUT()
        
        _ = PublisherSpy(sut.saveValues([]))
        
        XCTAssertEqual(store.receivedMessages, [.delete])
    }
    
    func test_saveValues_doesNotRequestInsertOnDeletionError() {
        let (sut, store) = makeSUT()
        
        _ = PublisherSpy(sut.saveValues([]))
        
        store.completeDelete(with: makeAnyError())
        XCTAssertEqual(store.receivedMessages, [.delete])
    }
    
    func test_saveValues_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        
        let spy = PublisherSpy(sut.saveValues([]))
        
        store.completeDelete(with: makeAnyError())
        XCTAssertNotNil(spy.error)
    }
    
    func test_saveValues_requestInsertOnDeletionSuccessWithValuesAndTimestamp() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let testData = makeTestValues()
        _ = PublisherSpy(sut.saveValues(testData.model))
        
        store.completeDeleteSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.delete, .insert(testData.local, timestamp)])
    }
    
    func test_saveValues_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        
        let spy = PublisherSpy(sut.saveValues([]))
        
        store.completeDeleteSuccessfully()
        store.completeInsert(with: makeAnyError())
        
        XCTAssertNotNil(spy.error)
    }
    
    func test_saveValues_succeedsOnSuccessfulInsertion() {
        let (sut, store) = makeSUT()
        
        let spy = PublisherSpy(sut.saveValues([]))
        
        store.completeDeleteSuccessfully()
        store.completeInsertSuccessfully()
        
        XCTAssertNil(spy.error)
        XCTAssertEqual(spy.values.count, 1)
    }
    
    //MARK: - Helpers
    
    func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: IPCLocalFetcher, store: IPCStoreSpy) {
        let store = IPCStoreSpy()
        let sut = IPCLocalFetcher(store: store, currentDate: currentDate)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
    
    func makeNonExpiredDate() -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: -maxCacheAgeInDays(), to: Date())! + 1
    }
    
    func makeExpiredDate() -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: -maxCacheAgeInDays(), to: Date())! - 1
    }
    
    func maxCacheAgeInDays() -> Int {
        1
    }
    
    func makeTestValues() -> (local: [IPCLocalValue], model: [IPCValue]) {
        let value1 = IPCValue(
            date: Date(string: "2020-08-18T04:12:23.06-05:00"),
            price: 39101.7,
            percentageChange: -0.47,
            volume: 13606767,
            change: -184.15)
        let value2 = IPCValue(
            date: Date(string: "2020-08-18T04:12:54.067-05:00"),
            price: 39106.77,
            percentageChange: -0.46,
            volume: 13725315,
            change: -179.08)
        
        let model: [IPCValue] = [value1, value2]
        let local: [IPCLocalValue] = [
            IPCLocalValue(date: value1.date, price: value1.price, percentageChange: value1.percentageChange, volume: value1.volume, change: value1.change),
            IPCLocalValue(date: value2.date, price: value2.price, percentageChange: value2.percentageChange, volume: value2.volume, change: value2.change)
        ]
        
        return (local, model)
    }
    
    class IPCStoreSpy: IPCStore {
        enum ReceivedMessage: Equatable {
            case delete
            case insert([IPCLocalValue], Date)
            case fetch
        }
        
        private(set) var receivedMessages: [ReceivedMessage] = []
        
        private var fetchSubjects: [PassthroughSubject<CacheResult, Error>] = []
        
        private var insertSubjects: [PassthroughSubject<Void, Error>] = []
        
        private var deleteSubjects: [PassthroughSubject<Void, Error>] = []
        
        func fetch() -> AnyPublisher<CacheResult, Error> {
            receivedMessages.append(.fetch)
            let subject = PassthroughSubject<CacheResult, Error>()
            fetchSubjects.append(subject)
            return subject.eraseToAnyPublisher()
        }
        
        func insert(_ values: [IPCLocalValue], timestamp: Date) -> AnyPublisher<Void, Error> {
            receivedMessages.append(.insert(values, timestamp))
            let subject = PassthroughSubject<Void, Error>()
            insertSubjects.append(subject)
            return subject.eraseToAnyPublisher()
        }
        
        func delete() -> AnyPublisher<Void, Error> {
            receivedMessages.append(.delete)
            let subject = PassthroughSubject<Void, Error>()
            deleteSubjects.append(subject)
            return subject.eraseToAnyPublisher()
        }
        
        func completeFetch(with error: Error, at index: Int = 0) {
            fetchSubjects[index].send(completion: .failure(error))
        }
        
        func completeFetch(with result: CacheResult, at index: Int = 0) {
            fetchSubjects[index].send(result)
            fetchSubjects[index].send(completion: .finished)
        }
        
        func completeDelete(with error: Error, at index: Int = 0) {
            deleteSubjects[index].send(completion: .failure(error))
        }
        
        func completeDeleteSuccessfully(at index: Int = 0) {
            deleteSubjects[index].send(())
            deleteSubjects[index].send(completion: .finished)
        }
        
        func completeInsert(with error: Error, at index: Int = 0) {
            insertSubjects[index].send(completion: .failure(error))
        }
        
        func completeInsertSuccessfully(at index: Int = 0) {
            insertSubjects[index].send(())
            insertSubjects[index].send(completion: .finished)
        }
    }
}
