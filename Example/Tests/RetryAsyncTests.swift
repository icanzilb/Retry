import Foundation
import XCTest
@testable import Retry

class RetryAsyncTests: XCTestCase {

    enum TestError: Error {
        case testError
    }

    //MARK: - async retries

    func testAsyncDefaults() {
        let e1 = expectation(description: "retry end")
        var output = ""

        retryAsync {
            output += "try"
            throw TestError.testError
            }
        .finalDefer {
            e1.fulfill()
        }

        waitForExpectations(timeout: 1.0) {error in
            XCTAssertTrue(error == nil)
            XCTAssertEqual(output, "trytrytry", "Didn't retry default(3) times asynchroniously")
        }
    }

    func testSyncMax() {
        let e1 = expectation(description: "retry end")
        var output = ""

        retryAsync (max: 5) {
            output += "try"
            throw TestError.testError
            }
        .finalDefer {
            e1.fulfill()
        }


        waitForExpectations(timeout: 1.0) {error in
            XCTAssertTrue(error == nil)
            XCTAssertEqual(output, "trytrytrytrytry", "Didn't retry 5 times asynchroniously")
        }
    }

    //MARK: - async retries + final catch

    func testSyncMaxFinalCatch() {
        let e1 = expectation(description: "retry end")
        var output = ""

        retryAsync (max: 5) {
            output += "try"
            throw TestError.testError
        }.finalCatch {_ in
            output += "-catch"
        }.finalDefer {
            e1.fulfill()
        }

        waitForExpectations(timeout: 1.0) {error in
            XCTAssertTrue(error == nil)
            XCTAssertEqual(output, "trytrytrytrytry-catch", "Didn't retry 5 times asynchroniously + catch")
        }
    }

    func testSyncMaxFinalCatchErrorMessage() {
        let e1 = expectation(description: "retry end")
        var output = ""

        retryAsync (max: 5) {
            output += "try"
            throw TestError.testError
            }.finalCatch {_ in
                output += "-\(TestError.testError)"
        }
        .finalDefer {
            e1.fulfill()
        }

        waitForExpectations(timeout: 1.0) {error in
            XCTAssertTrue(error == nil)
            XCTAssertEqual(output, "trytrytrytrytry-testError", "Didn't retry 5 times asynchroniously + catch")
        }
    }

    //MARK: - sync retries + strategy

    //TODO: - how to check for the immediate strategy???
    func testSyncMaxImmediate() {
        let e1 = expectation(description: "retry end")
        var output = ""
        var lastTime: UInt64?

        retryAsync (max: 5, retryStrategy: .immediate) {
            if let lastTime = lastTime {
                XCTAssertEqualWithAccuracy(StopWatch.deltaSince(t1: lastTime) , 0.001, accuracy: 0.01, "Didn't have the expected delay of 0")
            }

            output += "try"
            lastTime = mach_absolute_time()
            throw TestError.testError
        }
        .finalDefer {
            e1.fulfill()
        }

        waitForExpectations(timeout: 1.0) {error in
            XCTAssertTrue(error == nil)
            XCTAssertEqual(output, "trytrytrytrytry", "Didn't retry 2 times asynchroniously")
        }
    }

    func testSyncMaxDelay() {
        let e1 = expectation(description: "retry end")
        var output = ""
        var lastTime: UInt64?

        retryAsync (max: 5, retryStrategy: .delay(seconds: 2.0)) {
            if let lastTime = lastTime {
                XCTAssertEqualWithAccuracy(StopWatch.deltaSince(t1: lastTime) , 2.0, accuracy: 0.2, "Didn't have the expected delay of 2.0")
            }

            output += "try"
            lastTime = mach_absolute_time()
            throw TestError.testError
        }
        .finalDefer {
            e1.fulfill()
        }


        waitForExpectations(timeout: 10.0) {error in
            XCTAssertTrue(error == nil)
            XCTAssertEqual(output, "trytrytrytrytry", "Didn't retry 5 times asynchroniously")
        }
    }

    func testSyncMaxCustomRetryRepetitions() {
        let e1 = expectation(description: "retry end")
        var output = ""
        var lastTime: UInt64?

        retryAsync (max: 5, retryStrategy: .custom {count,_ in return count == 2 ? nil : 0} ) {
            if let lastTime = lastTime {
                XCTAssertEqualWithAccuracy(StopWatch.deltaSince(t1: lastTime) , 0.0, accuracy: 0.1, "Didn't have the expected delay of 2.0")
            }

            output += "try"
            lastTime = mach_absolute_time()
            throw TestError.testError
        }
        .finalDefer {
            e1.fulfill()
        }


        waitForExpectations(timeout: 10.0) {error in
            XCTAssertTrue(error == nil)
            XCTAssertEqual(output, "trytrytry", "Didn't retry 3 times asynchroniously")
        }
    }

    func testSyncMaxCustomRetryDelay() {
        let e1 = expectation(description: "retry end")
        var output = ""
        var lastTime: UInt64?
        var lastTestDelay: TimeInterval = 0.0

        retryAsync (max: 3, retryStrategy: .custom {count, lastDelay in return (lastDelay ?? 0.0) + 1.0} ) {

            if let lastTime = lastTime {
                lastTestDelay += 1.0
                let stopTime = StopWatch.deltaSince(t1: lastTime)
                //if only XCTAssertEqualWithAccuracy worked ...
                XCTAssert(stopTime > (lastTestDelay - lastTestDelay/10.0) && stopTime < (lastTestDelay + lastTestDelay/10.0),
                          "Didn't have the correct delay, expected \(lastTestDelay) timed \(stopTime)")
            }

            output += "try"
            lastTime = mach_absolute_time()
            throw TestError.testError
        }
        .finalDefer {
            e1.fulfill()
        }


        waitForExpectations(timeout: 5.0) {error in
            XCTAssertTrue(error == nil)
            XCTAssertEqual(output, "trytrytry", "Didn't retry 3 times asynchroniously")
        }
    }

    //MARK: - sync successful
    func testSuccessFirstTry() {
        let e1 = expectation(description: "retry end")
        var output = ""

        retryAsync {
            output += "try"
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
            XCTAssertEqual(output, "try-defer", "Didn't succeed")
        }
    }

    func testSuccessSecondTry() {
        let e1 = expectation(description: "retry end")
        var output = ""
        var succeed = false

        retryAsync (max: 3) {
            output += "try"
            if !succeed {
                succeed = true
                throw TestError.testError
            }
        }.finalCatch {_ in
            output += "-catch"
        }
        .finalDefer {
            e1.fulfill()
        }

        waitForExpectations(timeout: 10.0) {error in
            XCTAssertTrue(error == nil)
            XCTAssertEqual(output, "trytry", "Didn't succeed at second try")
        }
    }

    func testSuccessSecondTryDelayed() {
        let e1 = expectation(description: "retry end")

        var output = ""
        var succeed = false

        retryAsync (max: 3, retryStrategy: .custom(closure: {_, _ in return 1.0})) {
            output += "try"
            if !succeed {
                succeed = true
                throw TestError.testError
            }
        }.finalCatch {_ in
            output += "-catch"
        }
        .finalDefer {
            e1.fulfill()
        }


        waitForExpectations(timeout: 5.0) {error in
            XCTAssertTrue(error == nil)
            XCTAssertEqual(output, "trytry", "Didn't succeed at second try")
        }
    }
    
    func testAsyncFromBackgroundQueue() {
        let e1 = expectation(description: "final Defer")
        
        var output = ""
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            retryAsync (max: 3, retryStrategy: .immediate) {
                output.append("try")
                throw TestError.testError
                }.finalCatch {_ in
                    output.append("-catch")
                }.finalDefer {
                    e1.fulfill()
                }
    
        }
        
        waitForExpectations(timeout: 2.0) {error in
            XCTAssertTrue(error == nil)
            XCTAssertEqual(output, "trytrytry-catch", "Didn't succeed at the third try")
        }
    }
    
}
