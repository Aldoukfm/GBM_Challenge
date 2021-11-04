
import Foundation
import Combine

public struct ChartValueViewModel: Hashable {
    let x: Double
    let y: Double
}

public struct ChartViewModel {
    let values: [ChartValueViewModel]
}

extension ChartViewModel: Hashable {
    
}
