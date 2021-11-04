
import XCTest
import GBMChallengeKit
import TestHelpers
import Combine


final class IPCRemoteFetcherTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        XCTAssert(client.requestedURLs.isEmpty)
    }
    
    func test_fethValues_RequestDataFromURL() {
        let expectedURL = URL(string: "expectedURL.com")!
        let (sut, client) = makeSUT(url: expectedURL)
        
        _ = PublisherSpy(sut.fetchValues())
        
        XCTAssertEqual(client.requestedURLs, [expectedURL])
    }
    
    func test_fetchValues_deliversConnectivityErroronClientError() {
        let (sut, client) = makeSUT()
        
        let publisherSpy = PublisherSpy(sut.fetchValues())
        
        client.completeWith(error: makeAnyError())
        
        XCTAssertEqualError(publisherSpy.error, .connectivity)
    }
    
    func test_fetchValues_deliversInvalidDataErrorOnInvalidJSON() {
        
        let (sut, client) = makeSUT()
        
        let publisherSpy = PublisherSpy(sut.fetchValues())
        
        client.completeWith(data: makeInvalidData())
        
        XCTAssertEqualError(publisherSpy.error, .invalidData)
    }
    
    func test_fetchValues_deliversEmptyArrayOnValidDataWithNoItems() {
        
        let (sut, client) = makeSUT()
        
        let publisherSpy = PublisherSpy(sut.fetchValues())
        
        client.completeWith(data: makeEmptyListData())
        
        XCTAssertEqual([[]], publisherSpy.values)
    }
    
    func test_fetchValues_deliversValues() {
        let (sut, client) = makeSUT()
        
        let publisherSpy = PublisherSpy(sut.fetchValues())
        let (data, expectedValues) = makeTestValues()
        client.completeWith(data: data)
        
        XCTAssertEqual([expectedValues], publisherSpy.values)
    }
    
    //MARK: - Helpers
    
    func makeSUT(url: URL = URL(string: "anyURL.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: IPCRemoteFetcher, client: ClientSpy) {
        let client = ClientSpy()
        let sut = IPCRemoteFetcher(client: client, url: url)
        
        trackForMemoryLeaks(sut, file: file, line:  line)
        trackForMemoryLeaks(client, file: file, line: line)
        
        return (sut, client)
    }
    
    func makeInvalidData() -> Data {
        "invalid json".data(using: .utf8)!
    }
    
    func makeEmptyListData() -> Data {
        """
        []
        """.data(using: .utf8)!
    }
    
    func makeTestValues() -> (Data, [IPCValue]) {
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

        let values = [value1, value2]
        let data =
        """
        [
        {
        "date": "2020-08-18T04:12:23.06-05:00",
        "price": 39101.7,
        "percentageChange": -0.47,
        "volume": 13606767,
        "change": -184.15
        },
        {
        "date": "2020-08-18T04:12:54.067-05:00",
        "price": 39106.77,
        "percentageChange": -0.46,
        "volume": 13725315,
        "change": -179.08
        },
        ]
        """.data(using: .utf8)!
        
        return (data, values)
    }
    
    func XCTAssertEqualError(_ error1: Error?, _ error2: IPCRemoteFetcher.Error, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(error1 as? IPCRemoteFetcher.Error, error2, file: file, line: line)
    }
    
    class ClientSpy: HTTPClientType {
        
        var subjects: [PassthroughSubject<Data, Error>] = []
        var requestedURLs: [URL] = []
        
        func fetchData(from url: URL) -> AnyPublisher<Data, Error> {
            requestedURLs.append(url)
            let subject = PassthroughSubject<Data, Error>()
            subjects.append(subject)
            return subject.eraseToAnyPublisher()
        }
        
        func completeWith(error: Error, at index: Int = 0) {
            subjects[index].send(completion: .failure(error))
        }
        
        func completeWith(data: Data, at index: Int = 0) {
            subjects[index].send(data)
            subjects[index].send(completion: .finished)
        }
    }
}
