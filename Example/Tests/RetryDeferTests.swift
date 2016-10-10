import Foundation
import XCTest
@testable import Retry

class RetryDeferTests: XCTestCase {

    enum TestError: Error {
        case testError
    }

    func testDeferForRetainedRetrySync() {
        var output = ""
        let r: Retry? = retry (max: 3) {
            output += "try"
            throw TestError.testError
        }
        .finalCatch {_ in
            output += "-catch"
        }
        .finalDefer {
            output += "-defer"
        }
        output += "-end"

        XCTAssertNotNil(r)
        XCTAssertEqual(output, "trytrytry-catch-defer-end", "Didn't invoke defer before end")
    }

    func testDeferForRetainedRetryAsync() {
        let e1 = expectation(description: "retry end")
        var output = ""
        let r: Retry? = retryAsync (max: 3) {
            output += "try"
            throw TestError.testError
        }
        .finalCatch {_ in
            output += "-catch"
        }
        .finalDefer {
            output += "-defer"
            e1.fulfill()
        }

        waitForExpectations(timeout: 1.0) {error in
            XCTAssertTrue(error == nil)
            XCTAssertNotNil(r)
            XCTAssertEqual(output, "trytrytry-catch-defer", "Didn't invoke defer after last retry")
        }
    }

}
