

import XCTest
import Combine

public class PublisherSpy<P: Publisher> {
    public var error: P.Failure?
    private var cancellable: AnyCancellable?
    public var values: [P.Output] = []
    
    fileprivate var expectation: XCTestExpectation?
    
    public init(_ publisher: P) {
        
        cancellable = publisher.sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                self.error = error
            }
        }, receiveValue: { value in
            self.values.append(value)
            self.expectation?.fulfill()
        })
    }
}

public extension XCTestCase {
    
    func wait<P: Publisher>(_ publisher: P, timeout: TimeInterval = 0.1, file: StaticString = #filePath, line: UInt = #line) throws -> Result<P.Output, P.Failure> {
        
        var result: Result<P.Output, P.Failure>?
        let exp = expectation(description: "wait for result")
        let cancellable = publisher.sink { completion in
            switch completion {
            case .failure(let error):
                result = .failure(error)
            case .finished:
                break
            }
            exp.fulfill()
        } receiveValue: { output in
            result = .success(output)
        }
        
        wait(for: [exp], timeout: timeout)
        
        cancellable.cancel()
        
        return try XCTUnwrap(result, "Publisher did not produce output", file: file, line: line)
        
    }
    
    func wait<P: Publisher>(_ spy: PublisherSpy<P>, file: StaticString = #filePath, line: UInt = #line) throws -> Result<P.Output, P.Failure> {
        
        spy.expectation = XCTestExpectation(description: "Wait for first value")
        wait(for: [spy.expectation!], timeout: 0.1)
        
        let result: Result<P.Output, P.Failure>
        
        if let error = spy.error {
            result = .failure(error)
        } else {
            let value = try XCTUnwrap(spy.values.first, "Publisher did not produce output", file: file, line: line)
            result = .success(value)
        }
        
        return result
        
    }
    
    func wait<P: Publisher>(_ spy: PublisherSpy<P>, for expectation: XCTestExpectation, timeout: Double = 0.1, file: StaticString = #filePath, line: UInt = #line) {
        spy.expectation = expectation
        wait(for: [expectation], timeout: timeout)
    }
    
}

public extension Result {
    func getError() throws -> Failure {
        do {
            _ = try get()
            throw NSError(domain: "XCTest", code: -1, userInfo: [NSLocalizedDescriptionKey: "Expected error but succeded instead."])
        } catch {
            return error as! Failure
        }
    }
}
