
import Foundation
import Combine

public protocol IPCFetcher {
    func fetchValues() -> AnyPublisher<[IPCValue], Error>
}

