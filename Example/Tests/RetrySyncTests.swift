import Foundation
import XCTest
@testable import Retry

class RetrySyncTests: XCTestCase {

    enum TestError: Error {
        case testError
    }

    //MARK: - sync retries

    func testSyncDefaults() {
        var output = ""
        retry {
            output += "try"
            throw TestError.testError
        }
        output += "-end"
        XCTAssertEqual(output, "trytrytry-end", "Didn't retry default(3) times synchroniously")
    }

    func testSyncMax() {
        var output = ""
        retry (max: 5) {
            output += "try"
            throw TestError.testError
        }
        output += "-end"
        XCTAssertEqual(output, "trytrytrytrytry-end", "Didn't retry 5 times synchroniously")
    }

    //MARK: - sync retries + final catch

    func testSyncMaxFinalCatch() {
        var output = ""
        retry (max: 5) {
            output += "try"
            throw TestError.testError
            }.finalCatch {_ in
                output += "-catch"
        }
        output += "-end"
        XCTAssertEqual(output, "trytrytrytrytry-catch-end", "Didn't retry 5 times synchroniously + catch")
    }

    func testSyncMaxFinalCatchErrorMessage() {
        var output = ""
        retry (max: 5) {
            output += "try"
            throw TestError.testError
            }.finalCatch {_ in
                output += "-\(TestError.testError)"
        }
        output += "-end"
        XCTAssertEqual(output, "trytrytrytrytry-testError-end", "Didn't retry 5 times synchroniously + catch")
    }

    //MARK: - sync retries + strategy

    //TODO: - how to check for the immediate strategy???
    func testSyncMaxImmediate() {
        var output = ""
        var lastTime: UInt64?

        retry (max: 5, retryStrategy: .immediate) {
            if let lastTime = lastTime {
                XCTAssertEqualWithAccuracy(StopWatch.deltaSince(t1: lastTime) , 0.001, accuracy: 0.01, "Didn't have the expected delay of 0")
            }

            output += "try"
            lastTime = mach_absolute_time()
            throw TestError.testError
        }
        output += "-end"

        XCTAssertEqual(output, "trytrytrytrytry-end", "Didn't retry 2 times synchroniously")
    }

    func testSyncMaxDelay() {
        var output = ""
        var lastTime: UInt64?

        retry (max: 5, retryStrategy: .delay(seconds: 2.0)) {
            if let lastTime = lastTime {
                XCTAssertEqualWithAccuracy(StopWatch.deltaSince(t1: lastTime) , 2.0, accuracy: 0.01, "Didn't have the expected delay of 2.0")
            }

            output += "try"
            lastTime = mach_absolute_time()
            throw TestError.testError
        }
        output += "-end"

        XCTAssertEqual(output, "trytrytrytrytry-end", "Didn't retry 5 times synchroniously")
    }

    func testSyncMaxCustomRetryRepetitions() {
        var output = ""
        var lastTime: UInt64?

        retry (max: 5, retryStrategy: .custom {count,_ in return count == 2 ? nil : 0} ) {
            if let lastTime = lastTime {
                XCTAssertEqualWithAccuracy(StopWatch.deltaSince(t1: lastTime) , 0.0, accuracy: 0.01, "Didn't have the expected delay of 2.0")
            }

            output += "try"
            lastTime = mach_absolute_time()
            throw TestError.testError
        }
        output += "-end"

        XCTAssertEqual(output, "trytrytry-end", "Didn't retry 3 times synchroniously")
    }

    func testSyncMaxCustomRetryDelay() {
        var output = ""
        var lastTime: UInt64?
        var lastDelay: TimeInterval = 0.0

        retry (max: 5, retryStrategy: .custom {count, lastDelay in return (lastDelay ?? 0.0) + 0.2} ) {
            if let lastTime = lastTime {
                XCTAssertEqualWithAccuracy(StopWatch.deltaSince(t1: lastTime) , lastDelay, accuracy: 0.01, "Didn't have the expected delay of 2.0")
            }
            lastDelay += 0.2

            output += "try"
            lastTime = mach_absolute_time()
            throw TestError.testError
        }
        output += "-end"

        XCTAssertEqual(output, "trytrytrytrytry-end", "Didn't retry 5 times synchroniously")
    }

    //MARK: - sync successful
    func testSuccessFirstTry() {
        var output = ""
        retry {
            output += "try"
            }.finalCatch {_ in
                output += "-catch"
        }
        output += "-end"

        XCTAssertEqual(output, "try-end", "Didn't succeed")
    }

    func testSuccessSecondTry() {
        var output = ""
        var succeed = false

        retry {
            output += "try"
            if !succeed {
                succeed = true
                throw TestError.testError
            }
            }.finalCatch {_ in
                output += "-catch"
        }
        output += "-end"

        XCTAssertEqual(output, "trytry-end", "Didn't succeed at second try")
    }

    func testSuccessSecondTryDelayed() {
        var output = ""
        var succeed = false

        retry (max: 3, retryStrategy: .custom(closure: {_, _ in return 1.0})) {
            output += "try"
            if !succeed {
                succeed = true
                throw TestError.testError
            }
            }.finalCatch {_ in
                output += "-catch"
        }
        output += "-end"
        
        XCTAssertEqual(output, "trytry-end", "Didn't succeed at second try")
    }

}
