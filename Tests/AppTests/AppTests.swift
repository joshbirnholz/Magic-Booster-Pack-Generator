import App
import XCTest

final class AppTests: XCTestCase, @unchecked Sendable {
    func testNothing() throws {
        // Add your tests here
        XCTAssert(true)
    }

    static let allTests = [
        ("testNothing", testNothing)
    ]
}
