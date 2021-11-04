
import XCTest
import Combine
import CombineHelpers
import TestHelpers
import GBMChallengeKit

class CountdownCounterTests: XCTestCase {
    
    func test_init_doesRequestMessage() {
        let sut = makeSut()
        
        XCTAssertEqual(sut.receivedMessages, [])
    }
    
    var cancellables: [AnyCancellable] = []
    
    func test_start_deliverInitialCount() {
        let expectedInterval: DispatchTimeInterval = .microseconds(1)
        let expectedTimes = 10
        let expectedValue = Double(expectedTimes) * expectedInterval.toSeconds()
        let sut = makeSut(interval: expectedInterval, times: expectedTimes)
        let spy = PublisherSpy(sut.counter)
        
        sut.start()
        
        XCTAssertEqual(spy.values, [expectedValue])
    }
    
    func test_start_deliversCorrectValues() {
        let expectedInterval: DispatchTimeInterval = .microseconds(1)
        let expectedTimes = 10
        let expectedValues = (0...expectedTimes).reversed().map({ Double($0) * expectedInterval.toSeconds() })
        let sut = makeSut(interval: expectedInterval, times: expectedTimes)
        let spy = PublisherSpy(sut.counter)
        
        sut.start()
        
        let exp = expectation(description: "Wait for \(expectedTimes) values")
        exp.expectedFulfillmentCount = expectedTimes
        exp.assertForOverFulfill = true
        wait(spy, for: exp, timeout: 5)
        
        XCTAssertEqual(spy.values, expectedValues)
        
    }
    
    func test_stop_stopsSendingValues() {
        
        let expectedInterval: DispatchTimeInterval = .microseconds(1)
        let expectedTimes = 10
        let expectedValues = (0...expectedTimes).reversed().map({ Double($0) * expectedInterval.toSeconds() })
        let sut = makeSut(interval: expectedInterval, times: expectedTimes)
        let spy = PublisherSpy(sut.counter)
        
        
        let exp2Values = expectation(description: "Wait for 2 values")
        exp2Values.expectedFulfillmentCount = 2
        
        sut.start()
        wait(spy, for: exp2Values, timeout: 5)
        
        sut.stop()
        
        let expInv = expectation(description: "Dont send values")
        expInv.isInverted = true
        wait(spy, for: expInv, timeout: 0.001)
        
        XCTAssertEqual(spy.values, Array(expectedValues.prefix(3)))
        
    }
    
    func test_start_restartCounterAfterStop() {
        
        let expectedInterval: DispatchTimeInterval = .microseconds(1)
        let expectedTimes = 10
        let expectedValues = (0...expectedTimes).reversed().map({ Double($0) * expectedInterval.toSeconds() })
        let sut = makeSut(interval: expectedInterval, times: expectedTimes)
        let spy = PublisherSpy(sut.counter)
        
        
        let exp2Values = expectation(description: "Wait for 2 values")
        exp2Values.expectedFulfillmentCount = 2
        
        sut.start()
        wait(spy, for: exp2Values, timeout: 5)
        
        sut.stop()
        
        let expInv = expectation(description: "Dont send values")
        expInv.isInverted = true
        wait(spy, for: expInv, timeout: 0.001)
        
        XCTAssertEqual(spy.values, Array(expectedValues.prefix(3)))
        
        
        sut.start()
        let exp = expectation(description: "Wait for \(expectedTimes) values")
        exp.expectedFulfillmentCount = expectedTimes
        exp.assertForOverFulfill = true
        wait(spy, for: exp, timeout: 5)
        
        XCTAssertEqual(spy.values, Array(expectedValues.prefix(3)) + expectedValues)
    }
    
    //MARK: - Helpers
    
    func makeSut(interval: DispatchTimeInterval = .microseconds(1), times: Int = 10) -> CounterSpy {
        let sut = CounterSpy(interval: interval, times: times)
        
        trackForMemoryLeaks(sut)
        
        return sut
    }
    
    class CounterSpy: Counter {
        
        
        private let object: CountdownCounter
        
        var receivedMessages: [Message] = []
        
        enum Message {
            case start
            case stop
        }
        
        var counter: AnyPublisher<TimeInterval, Never> {
            object.counter
        }
        
        init(interval: DispatchTimeInterval, times: Int) {
            object = CountdownCounter(interval: interval, times: times)
        }
        
        func start() {
            receivedMessages.append(.start)
            object.start()
        }
        
        func stop() {
            receivedMessages.append(.stop)
            object.stop()
        }
    }
}

