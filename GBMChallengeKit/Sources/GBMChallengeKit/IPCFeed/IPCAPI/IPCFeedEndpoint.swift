
import Foundation

public enum IPCFeedEndpoint {
    case get
    
    public func url(baseURL: URL) -> URL {
        switch self {
        case .get:
            return baseURL.appendingPathComponent("/v3/cc4c350b-1f11-42a0-a1aa-f8593eafeb1e")
        }
    }
}

