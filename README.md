# Retry

[![Version](https://img.shields.io/cocoapods/v/Retry.svg?style=flat)](http://cocoapods.org/pods/Retry)
[![License](https://img.shields.io/cocoapods/l/Retry.svg?style=flat)](http://cocoapods.org/pods/Retry)
[![Platform](https://img.shields.io/cocoapods/p/Retry.svg?style=flat)](http://cocoapods.org/pods/Retry)

NB: Currently a very beta version.

## Example

Haven't you wished for `try` to sometimes try a little harder? Meet `retry`

To run the example project, clone the repo, and run `pod install` from the Example directory first.

The full test suite shows a variety of use cases.

### Synchronous retry

NB: The sync `retry` is not good for use on the main thread (because it will block it if you're having delays, etc). For the main thread it's better considering `retryAsync` (more info below).

Default parameters - retry three times without any delay:

```swift
retry {
  ... do some throwing work ...
}
```

Catching the last error, and adding a defer block after all tries have finished - will keep trying maximum `10` times. You can use either of the final blocks or both:

```swift
retry (max: 10) {
  ... do some throwing work ...
}
.finalCatch {lastError in
  print("This simply won't happen. Failed with: \(lastError)")
}
.finalDefer {
  print("Finished trying")
}
```

Add `2` second delay between the retries:

```swift
retry (max: 5, retryStrategy: .delay(seconds: 2.0)) {
  ... do some throwing work ...
}
```

Implement any custom delay logic (below is multiplying the waiting time after each try):

```swift
retry (max: 5, retryStrategy: .custom {count, lastDelay in return (lastDelay ?? 1.0) * 2.0} ) {
  ... do some throwing work ...
}
```

Limit the number of retries based on any custom logic - if you return `nil` from your custom strategy, `retry` will stop trying:

```swift
retry (max: 5, retryStrategy: .custom {count,_ in return count > 3 ? nil : 0} ) {
  ... do some throwing work ...
}
```

### Asynchronous retry

The syntax for `retryAsync` is exactly the same as for `retry`. The difference in behavior is if the first try fails `retryAsync` keeps trying asynchronously instead of blocking the current thread.

## Installation

__NB__: Before official Cocoapod release for swift 3.0, you can't use Retry via pods

Retry is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Retry"
```

## Author

Marin Todorov, 2016-present
Inspired by https://github.com/RxSwiftCommunity/RxSwiftExt

## License

Retry is available under the MIT license. See the LICENSE file for more info.
