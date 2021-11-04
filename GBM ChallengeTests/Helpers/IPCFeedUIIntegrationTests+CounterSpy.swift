
import Foundation
import Combine
import GBMChallengeKit

class CounterSpy: Counter {
    
    private let counterSubject: PassthroughSubject<TimeInterval, Never> = PassthroughSubject()
    
    var counter: AnyPublisher<TimeInterval, Never> {
        counterSubject.eraseToAnyPublisher()
    }
    
    func start() {
        counterSubject.send(60)
    }
    
    func stop() {
        
    }
    
    func send(_ timeInterval: TimeInterval) {
        counterSubject.send(timeInterval)
    }
}
