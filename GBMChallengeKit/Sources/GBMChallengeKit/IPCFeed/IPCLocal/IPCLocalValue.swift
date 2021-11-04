
import Foundation

public struct IPCLocalValue: Equatable {
    
    public let date: Date
    public let price: Float
    public let percentageChange: Float
    public let volume: Int
    public let change: Float
    
    public init(date: Date, price: Float, percentageChange: Float, volume: Int, change: Float) {
        self.date = date
        self.price = price
        self.percentageChange = percentageChange
        self.volume = volume
        self.change = change
    }
}
