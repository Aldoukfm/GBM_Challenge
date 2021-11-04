
import Foundation

public enum IPCFeedSection: Hashable {
    case chart
    case list
}

public enum IPCFeedItem: Hashable {
    case refreshStatus(RefreshStatusViewModel)
    case latest(LatestValueViewModel)
    case chart(ChartViewModel)
    case range(RangeControlViewModel)
    
    case value(ListValueViewModel)
}
