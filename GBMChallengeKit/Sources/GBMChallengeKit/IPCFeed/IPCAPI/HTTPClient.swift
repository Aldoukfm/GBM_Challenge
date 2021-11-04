
import Foundation
import Combine

public protocol HTTPClientType {
    func fetchData(from url: URL) -> AnyPublisher<Data, Error>
}

public class HTTPClient: HTTPClientType {
    
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func fetchData(from url: URL) -> AnyPublisher<Data, Error> {
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        return session.dataTaskPublisher(for: request)
            .mapError({ $0 as Error })
            .map(\.data)
            .eraseToAnyPublisher()
    }
}
