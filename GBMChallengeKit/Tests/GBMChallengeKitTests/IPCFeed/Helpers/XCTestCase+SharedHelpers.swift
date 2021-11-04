
import XCTest
import GBMChallengeKit

extension XCTestCase {
    
    func makeAnyError() -> NSError {
        NSError(domain: "Test", code: 0)
    }
    
    func makeUniqueValues() -> [IPCValue] {
        let value1 = IPCValue(
            date: Date(string: "2020-08-18T04:12:23.06-05:00"),
            price: Float.random(in: 1...1000),
            percentageChange: Float.random(in: -1...1),
            volume: Int.random(in: 1...1000),
            change: Float.random(in: -1000...1000))
        let value2 = IPCValue(
            date: Date(string: "2020-08-18T04:12:54.067-05:00"),
            price: Float.random(in: 1...1000),
            percentageChange: Float.random(in: -1...1),
            volume: Int.random(in: 1...1000),
            change: Float.random(in: -1000...1000))
        return [value1, value2]
    }
}

extension Date {
    init(string: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSZZZZZ"
        let date = dateFormatter.date(from: string)!
        self.init(timeIntervalSince1970: date.timeIntervalSince1970)
    }
}
