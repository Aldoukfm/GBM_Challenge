
import Foundation
import Combine

struct DispatchTimerConfiguration {
    let queue: DispatchQueue?
    let interval: DispatchTimeInterval
    let leeway: DispatchTimeInterval
    let times: Subscribers.Demand
}

public extension Publishers {
    struct DispatchTimer: Publisher {
        public typealias Output = DispatchTime
        public typealias Failure = Never
        
        let configuration: DispatchTimerConfiguration
        
        init(configuration: DispatchTimerConfiguration) {
            self.configuration = configuration
        }
        
        public func receive<S: Subscriber>(subscriber: S)
        where Failure == S.Failure,
              Output == S.Input {
                  let subscription = DispatchTimerSubscription(
                    subscriber: subscriber,
                    configuration: configuration
                  )
                  subscriber.receive(subscription: subscription)
              }
    }
}

private final class DispatchTimerSubscription<S: Subscriber>: Subscription
where S.Input == DispatchTime {
    
    let configuration: DispatchTimerConfiguration
    var times: Subscribers.Demand
    var requested: Subscribers.Demand = .none
    var source: DispatchSourceTimer? = nil
    var subscriber: S?
    
    init(subscriber: S,
         configuration: DispatchTimerConfiguration) {
        self.configuration = configuration
        self.subscriber = subscriber
        self.times = configuration.times
    }
    
    func request(_ demand: Subscribers.Demand) {
        guard times > .none else {
            subscriber?.receive(completion: .finished)
            return
        }
        
        requested += demand
        
        if source == nil, requested > .none {
            
            let source = DispatchSource.makeTimerSource(queue: configuration.queue)
            
            source.schedule(deadline: .now() + configuration.interval,
                            repeating: configuration.interval,
                            leeway: configuration.leeway)
            
            
            source.setEventHandler { [weak self] in
                
                guard let self = self,
                      self.requested > .none else { return }
                
                self.requested -= .max(1)
                self.times -= .max(1)
                
                _ = self.subscriber?.receive(.now())
                
                if self.times == .none {
                    self.subscriber?.receive(completion: .finished)
                }
            }
            
            self.source = source
            source.activate()
        }
    }
    
    func cancel() {
        source = nil
        subscriber = nil
    }
}

public extension Publishers {
    static func timer(queue: DispatchQueue? = nil,
                      interval: DispatchTimeInterval,
                      leeway: DispatchTimeInterval = .nanoseconds(0),
                      times: Subscribers.Demand = .unlimited)
    -> Publishers.DispatchTimer {
        return Publishers.DispatchTimer(
            configuration: .init(queue: queue,
                                 interval: interval,
                                 leeway: leeway,
                                 times: times)
        )
    }
}
