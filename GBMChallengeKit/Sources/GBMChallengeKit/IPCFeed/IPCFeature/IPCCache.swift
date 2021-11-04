
import Foundation
import Combine

public protocol IPCCache {
    func saveValues(_ values: [IPCValue]) -> AnyPublisher<Void, Error>
}
