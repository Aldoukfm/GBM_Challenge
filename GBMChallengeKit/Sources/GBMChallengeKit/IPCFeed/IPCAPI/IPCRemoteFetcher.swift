
import Foundation
import Combine

public class IPCRemoteFetcher: IPCFetcher {
    
    private let client: HTTPClientType
    private let url: URL
    
    public init(client: HTTPClientType, url: URL) {
        self.client = client
        self.url = url
    }
    
    public func fetchValues() -> AnyPublisher<[IPCValue], Swift.Error> {
        return client.fetchData(from: url)
            .mapError({ _ in Error.connectivity })
            .tryMap({ data in
                let response = try IPCResponseDecoder.map(data)
                return Self.map(response)
            })
            .eraseToAnyPublisher()
    }
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
        case unknown
    }
}

extension IPCRemoteFetcher {
    private static func map(_ response: IPCResponseDecoder.Response) -> [IPCValue] {
        return response.map({
            IPCValue(date: $0.date, price: $0.price, percentageChange: $0.percentageChange, volume: $0.volume, change: $0.change)
        })
    }
}
