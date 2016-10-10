import Foundation
import XCTest
@testable import Retry

class RetrySyncThreadsTests: XCTestCase {

    enum TestError: Error {
        case testError
    }

    //MARK: - stay on main thread

    func testStayOnMainThread_whenImmediateStrategy() {
        var result = ""

        retry(max: 3, retryStrategy: .immediate, {
            XCTAssertTrue(Thread.isMainThread, "Not on main thread")
            result += "try-"
            throw TestError.testError
        })
        .finalCatch {_ in
            XCTAssertTrue(Thread.isMainThread, "Not on main thread")
            result += "catch-"
        }
        .finalDefer {
            XCTAssertTrue(Thread.isMainThread, "Not on main thread")
            result += "defer"
        }
        XCTAssertEqual(result, "try-try-try-catch-defer", "Did not execute blocks in right order")
    }

    func testStayOnMainThread_whenDelayStrategy() {
        var result = ""

        retry(max: 3, retryStrategy: .delay(seconds: 1.0), {
            XCTAssertTrue(Thread.isMainThread, "Not on main thread")
            result += "try-"
            throw TestError.testError
        })
        .finalCatch {_ in
            XCTAssertTrue(Thread.isMainThread, "Not on main thread")
            result += "catch-"
        }
        .finalDefer {
            XCTAssertTrue(Thread.isMainThread, "Not on main thread")
            result += "defer"
        }
        XCTAssertEqual(result, "try-try-try-catch-defer", "Did not execute blocks in right order")
    }

    func testStayOnMainThread_whenCustomStrategy() {
        var result = ""

        retry(max: 3, retryStrategy: .custom(closure: {_, _ in return 0.2}), {
            XCTAssertTrue(Thread.isMainThread, "Not on main thread")
            result += "try-"
            throw TestError.testError
        })
        .finalCatch {_ in
            XCTAssertTrue(Thread.isMainThread, "Not on main thread")
            result += "catch-"
        }
        .finalDefer {
            XCTAssertTrue(Thread.isMainThread, "Not on main thread")
            result += "defer"
        }
        XCTAssertEqual(result, "try-try-try-catch-defer", "Did not execute blocks in right order")
    }

    //MARK: - stay on background thread

    func testStayOnBgThread_whenImmediateStrategy() {
        var result = ""

        let finished = expectation(description: "finished")

        DispatchQueue(label: "bg", qos: DispatchQoS.background).async {
            retry(max: 3, retryStrategy: .immediate, {
                XCTAssertFalse(Thread.isMainThread, "Not on main thread")
                result += "try-"
                throw TestError.testError
            })
            .finalCatch {_ in
                XCTAssertFalse(Thread.isMainThread, "Not on main thread")
                result += "catch-"
            }
            .finalDefer {
                XCTAssertFalse(Thread.isMainThread, "Not on main thread")
                result += "defer"
                finished.fulfill()
            }
        }

        waitForExpectations(timeout: 5, handler: {_ in
            XCTAssertEqual(result, "try-try-try-catch-defer", "Did not execute blocks in right order")
        })
    }

    func testStayOnBgThread_whenDelayStrategy() {
        var result = ""

        let finished = expectation(description: "finished")

        DispatchQueue(label: "bg", qos: DispatchQoS.background).async {
            retry(max: 3, retryStrategy: .delay(seconds: 0.2), {
                XCTAssertFalse(Thread.isMainThread, "Not on main thread")
                result += "try-"
                throw TestError.testError
            })
                .finalCatch {_ in
                    XCTAssertFalse(Thread.isMainThread, "Not on main thread")
                    result += "catch-"
                }
                .finalDefer {
                    XCTAssertFalse(Thread.isMainThread, "Not on main thread")
                    result += "defer"
                    finished.fulfill()
            }
        }

        waitForExpectations(timeout: 5, handler: {_ in
            XCTAssertEqual(result, "try-try-try-catch-defer", "Did not execute blocks in right order")
        })
    }

    func testStayOnBgThread_whenCustomStrategy() {
        var result = ""

        let finished = expectation(description: "finished")

        DispatchQueue(label: "bg", qos: DispatchQoS.background).async {
            retry(max: 3, retryStrategy: .custom(closure: {_, _ in 0.2}), {
                XCTAssertFalse(Thread.isMainThread, "Not on main thread")
                result += "try-"
                throw TestError.testError
            })
            .finalCatch {_ in
                XCTAssertFalse(Thread.isMainThread, "Not on main thread")
                result += "catch-"
            }
            .finalDefer {
                XCTAssertFalse(Thread.isMainThread, "Not on main thread")
                result += "defer"
                finished.fulfill()
            }
        }

        waitForExpectations(timeout: 5, handler: {_ in
            XCTAssertEqual(result, "try-try-try-catch-defer", "Did not execute blocks in right order")
        })
    }

}
