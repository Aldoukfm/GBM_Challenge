
import Foundation
import Combine

public enum RangeOption: Hashable {
    
    case minute(Int)
    case hour(Int)
    case max
    
    public func toSeconds() -> Double {
        switch self {
        case .minute(let t):
            return Double(t) * 60
        case .hour(let t):
            return Double(t) * 3600
        case .max:
            return 10 * 31536000
        }
    }
    
    public static var defaultOptions: [RangeOption] {
        [.minute(10), .minute(30), .hour(1), .max].reversed()
    }
}

public struct RangeControlViewModel {
    let options: [String]
    let selectedIndex: CurrentValueSubject<Int, Never>
}

extension RangeControlViewModel: Hashable {
    public static func ==(lhs: RangeControlViewModel, rhs: RangeControlViewModel) -> Bool {
        return lhs.options == rhs.options
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(options)
    }
}
