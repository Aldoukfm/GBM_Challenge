
import Foundation
import Combine
import CombineHelpers

public struct RefreshStatusViewModel {

    @HashableIgnore
    var titlePublisher: AnyPublisher<String?, Never>
    
}

extension RefreshStatusViewModel: Hashable {

}
