
import Foundation

internal struct RemoteIPCValue: Decodable {
    public let date: Date
    public let price: Float
    public let percentageChange: Float
    public let volume: Int
    public let change: Float
}

internal class IPCResponseDecoder {
    
    internal typealias Response = [RemoteIPCValue]
    
    internal static func map(_ data: Data) throws -> Response {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSZZZZZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw IPCRemoteFetcher.Error.invalidData
        }
    }
}
