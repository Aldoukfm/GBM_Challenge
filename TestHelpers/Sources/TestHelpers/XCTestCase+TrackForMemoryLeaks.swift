
import XCTest

extension XCTestCase {
    public func trackForMemoryLeaks(_ object: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak object] in
            XCTAssertNil(object, "Instance should be deallocated. Potential memory leak.", file: file, line: line)
        }
    }
}
