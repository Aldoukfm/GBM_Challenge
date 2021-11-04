
import XCTest
import GBMChallengeKit
import TestHelpers
import Combine

class HTTPClientTests: XCTestCase {
    
    func test_init() {
        let sut = makeSUT()
        XCTAssertNotNil(sut)
    }
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_fetchData_performsGETRequestWithURL() throws {
        let sut = makeSUT()
        let url = makeAnyURL()
        
        let spy = PublisherSpy(URLProtocolStub.requestObserver())
        _ = PublisherSpy(sut.fetchData(from: url))
        
        let request = try wait(spy).get()
        XCTAssertEqual(["GET"], [request.httpMethod])
        XCTAssertEqual([url], [request.url])
    }
    
    func test_fetchData_failsOnRequestError() {
        let sut = makeSUT()
        let url = makeAnyURL()
        
        URLProtocolStub.stub(data: nil, response: nil, error: makeAnyError())
        
        XCTAssertNoThrow(try wait(sut.fetchData(from: url)).getError())
    }
    
    func test_fetchData_succeedsWithData() throws {
        let sut = makeSUT()
        let url = makeAnyURL()
        
        let expectedData = Data()
        URLProtocolStub.stub(data: expectedData, response: makeAnyOKResponse(), error: nil)
        
        let data = try wait(sut.fetchData(from: url)).get()
        
        XCTAssertEqual(data, expectedData)
    }
    
    //MARK: - Helpers
    
    func makeSUT() -> HTTPClient {
        let sut = HTTPClient()
        trackForMemoryLeaks(sut)
        return sut
    }
    
    func makeAnyURL() -> URL {
        URL(string: "anyURL.com")!
    }
    
    func makeAnyOKResponse() -> URLResponse {
        HTTPURLResponse(url: makeAnyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var _requestObserver: PassthroughSubject<URLRequest, Never>!
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func requestObserver() -> AnyPublisher<URLRequest, Never> {
            _requestObserver.eraseToAnyPublisher()
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
            _requestObserver = PassthroughSubject()
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            _requestObserver?.send(completion: .finished)
            _requestObserver = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            _requestObserver.send(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }

            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}
