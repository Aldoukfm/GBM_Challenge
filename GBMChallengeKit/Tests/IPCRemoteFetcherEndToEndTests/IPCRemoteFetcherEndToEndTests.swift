
import XCTest
import GBMChallengeKit
import TestHelpers

class IPCRemoteFetcherEndToEndTests: XCTestCase {
    
    func test_endToEndTestServer_fetchData_matchesFixedTestData() throws {
        let sut = makeSUT()
        
        let values = try wait(sut.fetchValues(), timeout: 5).get()
        
        XCTAssertEqual(values.suffix(5), expectedValues())
    }
    
    //MARK: - Helpers
    
    func makeSUT() -> IPCRemoteFetcher {
        let client = HTTPClient()
        let url = IPCFeedEndpoint.get.url(baseURL: URL(string: "https://run.mocky.io")!)
        return IPCRemoteFetcher(client: client, url: url)
    }
    
    func expectedValues() -> [IPCValue] {
        
        return [
            
            IPCValue(date: Date(string: "2020-08-18T04:11:21.06-05:00"), price: 39117.84, percentageChange: -0.43, volume: 13305336, change: -168.01),
            IPCValue(date: Date(string: "2020-08-18T04:11:52.06-05:00"), price: 39113.98, percentageChange: -0.44, volume: 13355546, change: -171.87),
            IPCValue(date: Date(string: "2020-08-18T04:12:23.06-05:00"), price: 39101.7, percentageChange: -0.47, volume: 13606767, change: -184.15),
            IPCValue(date: Date(string: "2020-08-18T04:12:54.067-05:00"), price: 39106.77, percentageChange: -0.46, volume: 13725315, change: -179.08),
            IPCValue(date: Date(string: "2020-08-18T04:13:25.063-05:00"), price: 39100.58, percentageChange: -0.47, volume: 13786034, change: -185.27),
            
        ]
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
