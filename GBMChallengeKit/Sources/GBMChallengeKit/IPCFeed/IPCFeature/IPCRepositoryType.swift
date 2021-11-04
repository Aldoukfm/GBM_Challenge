
import Foundation
import Combine

public enum IPCRepositorySource: Equatable {
    case cache
    case remote
}

public protocol IPCRepositoryType {
    func fetchValues() -> AnyPublisher<(IPCRepositorySource, [IPCValue]), Error>
}
