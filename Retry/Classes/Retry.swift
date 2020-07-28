//
//  Created by Marin Todorov
//  Copyright (c) 2016-present Underplot ltd. All rights reserved.
//
//  This source code is covered by the MIT license. Consult the LICENSE file.
//

import Foundation

open class Retry {

    public enum Strategy {
        case immediate
        case delay(seconds: Double)
        case custom(closure: (_ currentIteration: Int, _ lastDelay: TimeInterval?)-> TimeInterval?)
    }

    private let closure: () throws -> Void
    private let maxCount: Int
    private let strategy: Strategy

    private var done: Bool = false
    private let operatingQueue: DispatchQueue?

    private var errorHandler: ((Error) -> Void)?
    private var currentRepeat = 0
    private var lastError: Error?
    private var lastDelay: TimeInterval? = nil
    private var deferHandler: (() -> Void)?

    init(operatingQueue: DispatchQueue? = nil, closure: @escaping () throws -> Void, max: Int, strategy: Strategy) {
        self.operatingQueue = operatingQueue
        self.closure = closure
        self.maxCount = max
        self.strategy = strategy
    }

    deinit {
        print("deinit retry")
    }
    
    private func threadSafe(handler: @escaping ()-> Void) {
        if let queue = operatingQueue {
            queue.async(execute: handler)
        } else {
            handler()
        }
    }

    @discardableResult
    public func finalCatch(_ handler: @escaping ((Error)-> Void)) -> Self {
        threadSafe {
            if !self.done {
                self.errorHandler = handler
            } else if let lastError = self.lastError {
                handler(lastError)
            }
        }
        return self
    }

    @discardableResult
    public func finalDefer(_ handler: @escaping (()-> Void)) -> Self {
        threadSafe {
            if !self.done {
                self.deferHandler = handler
            } else {
                handler()
            }
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
            lastError = e
            self.errorHandler?(e)
        }
        self.deferHandler?()
        self.done = true
    }

    @discardableResult
    fileprivate func running() -> Self {
        var error: Error? = nil
        
        do {
            try closure()
        }
        catch let e {
            error = e
        }
        
        guard let e = error else {
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
        
        if let queue = operatingQueue {
            queue.asyncAfter(deadline: .now() + delay, execute: retry)
        } else {
            Thread.sleep(forTimeInterval: delay)
            retry()
        }

        return self
    }
}

@discardableResult
public func retry( max: Int = 3, retryStrategy: Retry.Strategy = .immediate, _ closure: @escaping () throws -> Void) -> Retry {
    return Retry(closure: closure, max: max, strategy: retryStrategy).running()
}

@discardableResult
public func retryAsync( max: Int = 3, retryStrategy: Retry.Strategy = .immediate, _ closure: @escaping () throws -> Void) -> Retry {
    let customQueue: DispatchQueue? = Thread.isMainThread ? nil : DispatchQueue(label: "RetryQueue")
    return Retry(operatingQueue: customQueue, closure: closure, max: max, strategy: retryStrategy).running()
}
