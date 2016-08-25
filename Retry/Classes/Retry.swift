//
//  Created by Marin Todorov
//  Copyright (c) 2016-present Underplot ltd. All rights reserved.
//
//  This source code is covered by the MIT license. Consult the LICENSE file.
//

public enum RetryStrategy {
    case immediate
    case delay(seconds: Double)
    case custom(closure: (_ currentIteration: Int, _ lastDelay: TimeInterval?)->TimeInterval?)
}

open class Retry {

    private let closure: () throws -> Void
    private let maxCount: Int
    private let strategy: RetryStrategy
    private let async: Bool

    private var errorHandler: ((Error) -> Void)?
    private var currentRepeat = 0
    private var lastError: Error?
    private var lastDelay: TimeInterval? = nil
    private var deferHandler: (() -> Void)?

    init(async: Bool, closure: @escaping () throws -> Void, max: Int, strategy: RetryStrategy) {
        self.async = async
        self.closure = closure
        self.maxCount = max
        self.strategy = strategy
    }

    deinit {
        print("deinit retry")
    }

    @discardableResult
    open func finalCatch(_ handler: ((Error) -> Void)) -> Self {
        if async {
            errorHandler = handler
        } else if let lastError = lastError {
            handler(lastError)
        }
        return self
    }

    @discardableResult
    open func finalDefer(_ handler: (() -> Void)) -> Self {
        if async && lastError != nil {
            deferHandler = handler
        } else {
            handler()
        }
        return self
    }

    private var delayDuration: TimeInterval? {
        switch strategy {
        case .immediate: return 0
        case .delay(let delay): return delay
        case .custom(let closure):
            if let delay = closure(currentRepeat, lastDelay) {
                lastDelay = delay
                return delay
            }
            return nil
        }
    }

    private func retry() {
        currentRepeat += 1
        running()
    }

    private func finalize(error: Error? = nil) {
        if let e = error {
            self.errorHandler?(e)
        }
        self.deferHandler?()
    }

    @discardableResult
    fileprivate func running() -> Self {
        lastError = nil

        do {
            try closure()
        }
        catch let e {
            lastError = e
        }

        guard let e = lastError else {
            finalize()
            return self
        }

        guard self.currentRepeat+1 < self.maxCount else {
            finalize(error: e)
            return self
        }

        guard let delay = delayDuration else {
            finalize(error: e)
            return self
        }

        if async {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: retry)
        } else {
            Thread.sleep(forTimeInterval: delay)
            retry()
        }

        return self
    }
}

@discardableResult
public func retry(max: Int = 3, retryStrategy: RetryStrategy = .immediate, _ closure: @escaping () throws -> Void) -> Retry {
    return Retry(async: false, closure: closure, max: max, strategy: retryStrategy).running()
}

@discardableResult
public func retryAsync(max: Int = 3, retryStrategy: RetryStrategy = .immediate, _ closure: @escaping () throws -> Void) -> Retry {
    return Retry(async: true, closure: closure, max: max, strategy: retryStrategy).running()
}
