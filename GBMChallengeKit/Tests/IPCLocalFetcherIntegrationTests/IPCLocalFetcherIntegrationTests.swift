
import XCTest
import TestHelpers
import GBMChallengeKit

class IPCLocalFetcherIntegrationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }
    
    func test_fetch_failsOnEmptyCache() {
        let sut = makeSut()
        
        XCTAssertNoThrow(try wait(sut.fetchValues()).getError())
    }
    
    func test_fetchValues_deliversValuesSavedOnASeparateInstance() throws {
        let sut = makeSut()
        let expectedValues = makeTestValues()
        
        save(expectedValues, on: makeSut())
        
        let values = try wait(sut.fetchValues()).get()
        
        XCTAssertEqual(values, expectedValues)
    }
    
    func test_fetchValues_overridesValuesSavedOnASeparateInstance() throws {
        let sut = makeSut()
        let firstValues = makeUniqueValues()
        let latestValues = makeUniqueValues()
        save(firstValues, on: makeSut())
        save(latestValues, on: makeSut())
        
        let values = try wait(sut.fetchValues()).get()
        
        XCTAssertEqual(values, latestValues)
    }
    
    //MARK: - Helpers
    
    func makeSut(file: StaticString = #filePath, line: UInt = #line) -> IPCLocalFetcher {
        
        let store = IPCFileStore(storeURL: makeTestStoreURL())
        
        let sut = IPCLocalFetcher(store: store)
        
        return sut
    }
    
    func makeTestStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
    
    func setupEmptyStoreState() {
        try? FileManager.default.removeItem(at: makeTestStoreURL())
    }
    
    func makeTestValues() -> [IPCValue] {
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
        
        return [value1, value2]
    }
    
    func makeUniqueValues() -> [IPCValue] {
        let value1 = IPCValue(
            date: Date(string: "2020-08-18T04:12:23.06-05:00"),
            price: Float.random(in: 1...1000),
            percentageChange: Float.random(in: -1...1),
            volume: Int.random(in: 1...1000),
            change: Float.random(in: -1000...1000))
        let value2 = IPCValue(
            date: Date(string: "2020-08-18T04:12:54.067-05:00"),
            price: Float.random(in: 1...1000),
            percentageChange: Float.random(in: -1...1),
            volume: Int.random(in: 1...1000),
            change: Float.random(in: -1000...1000))
        return [value1, value2]
    }
    
    func save(_ values: [IPCValue], on sut: IPCLocalFetcher, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNoThrow(try wait(sut.saveValues(values)).get(), file: file, line: line)
    }
}

extension Date {
    init(string: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSZZZZZ"
        let date = dateFormatter.date(from: string)!
        self.init(timeIntervalSince1970: date.timeIntervalSince1970)
    }
}
