
import Foundation
import Combine
import CombineHelpers

public protocol Counter {
    var counter: AnyPublisher<TimeInterval, Never> { get }
    func start()
    func stop()
}

public class CountdownCounter: Counter {
    
    private var interval: DispatchTimeInterval
    private var times: Int
    
    public var counter: AnyPublisher<TimeInterval, Never> {
        counterSubject.eraseToAnyPublisher()
    }
    
    private let counterSubject: PassthroughSubject<TimeInterval, Never> = PassthroughSubject()
    
    private var counterCancellable: AnyCancellable?
    
    public init(interval: DispatchTimeInterval, times: Int) {
        self.interval = interval
        self.times = times
    }
    
    public func start() {
        counterCancellable?.cancel()
        
        let values = (0..<times).reversed().map({ Double($0) * self.interval.toSeconds() })
        
        counterCancellable = Publishers
            .timer(queue: .main, interval: interval, leeway: .nanoseconds(0), times: .max(times))
            .zip(values.publisher)
            .map({ (_, value) -> TimeInterval in
                return value
            })
            .subscribe(counterSubject)
        
        counterSubject.send(Double(self.times) * self.interval.toSeconds())
    }
    
    public func stop() {
        counterCancellable?.cancel()
    }
}

public extension DispatchTimeInterval {
    func toSeconds() -> TimeInterval {
        switch self {
        case .seconds(let t):
            return Double(t)
        case .milliseconds(let t):
            return Double(t) * 0.001
        case .microseconds(let t):
            return Double(t) * 0.000001
        case .nanoseconds(let t):
            return Double(t) * 0.000000001
        case .never:
            return 0
        @unknown default:
            return 0
        }
    }
}

