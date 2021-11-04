
import XCTest
import TestHelpers
import Combine
import GBMChallengeKit

class IPCFileStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }
    
    func test_fetch_failsOnEmptyCache() {
        let sut = makeSut()
        
        XCTAssertNoThrow(try wait(sut.fetch()).getError())
    }
    
    func test_fetch_deliversValuesOnNonEmptyCache() throws {
        let sut = makeSut()
        let expectedResult: CacheResult = (makeTestValues(), Date())
        insert(expectedResult, on: sut)
        
        let result = try wait(sut.fetch()).get()
        
        XCTAssertEqual(result.values, expectedResult.values)
        XCTAssertEqual(result.timestamp, expectedResult.timestamp)
    }
    
    func test_delete_deletesCache() throws {
        let sut = makeSut()
        let expectedResult: CacheResult = (makeTestValues(), Date())
        insert(expectedResult, on: sut)
        
        XCTAssertNoThrow(try wait(sut.delete()).get())
        
        XCTAssertThrowsError(try wait(sut.fetch()).get())
    }
    
    func test_insert_savesCache() throws {
        let sut = makeSut()
        let expectedResult: CacheResult = (makeTestValues(), Date())
        
        _ = try wait(sut.insert(expectedResult.values, timestamp: expectedResult.timestamp)).get()
        
        let result = try wait(sut.fetch()).get()
        
        XCTAssertEqual(result.values, expectedResult.values)
        XCTAssertEqual(result.timestamp, expectedResult.timestamp)
    }
    
    var cancellables: [AnyCancellable] = []
    func test_storeSideEffects_runSerially() {
        let sut = makeSut()
        var completedOperationsInOrder = [XCTestExpectation]()
        
        let op1 = expectation(description: "Operation 1")
        let cache: CacheResult = (makeTestValues(), Date())
        sut.insert(cache.values, timestamp: cache.timestamp).sink(receiveCompletion: { _ in
            completedOperationsInOrder.append(op1)
            op1.fulfill()
        }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        let op2 = expectation(description: "Operation 2")
        sut.delete().sink(receiveCompletion: { _ in
            completedOperationsInOrder.append(op2)
            op2.fulfill()
        }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        let op3 = expectation(description: "Operation 3")
        sut.insert(cache.values, timestamp: cache.timestamp).sink(receiveCompletion: { _ in
            completedOperationsInOrder.append(op3)
            op3.fulfill()
        }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 4, handler: nil)
        
        XCTAssertEqual([op1, op2, op3], completedOperationsInOrder)
    }
    
    //MARK: Helpers
    
    func makeSut(file: StaticString = #filePath, line: UInt = #line) -> IPCFileStore {
        
        let sut = IPCFileStore(storeURL: makeTestStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    func makeTestStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
    
    func makeTestValues() -> [IPCLocalValue] {
        let value1 = IPCLocalValue(
            date: Date(string: "2020-08-18T04:12:23.06-05:00"),
            price: 39101.7,
            percentageChange: -0.47,
            volume: 13606767,
            change: -184.15)
        let value2 = IPCLocalValue(
            date: Date(string: "2020-08-18T04:12:54.067-05:00"),
            price: 39106.77,
            percentageChange: -0.46,
            volume: 13725315,
            change: -179.08)
        
        return [value1, value2]
    }
    
    func insert(_ result: CacheResult, on sut: IPCFileStore) {
        XCTAssertNoThrow(try wait(sut.insert(result.values, timestamp: result.timestamp)).get())
    }
    
    func setupEmptyStoreState() {
        try? FileManager.default.removeItem(at: makeTestStoreURL())
    }
}
