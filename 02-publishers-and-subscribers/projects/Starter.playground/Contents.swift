import Foundation
import Combine
import _Concurrency

var subscriptions = Set<AnyCancellable>()

example(of: "concurrency") {
  let subject = CurrentValueSubject<Int, Never>(0)
  
  Task {
    for await element in subject.values {
      print("Element: \(element)")
    }
    
    print("Completed")
  }
  
  subject.send(1)
  subject.send(2)
  subject.send(3)
  
  subject.send(completion: .finished)
}

example(of: "Type erasure") {
  print("current subscriptions: \(subscriptions.count)")

  let subject = PassthroughSubject<Int, Never>()
  
  /// Turn subject to `AnyPublisher`
  let publisher = subject.eraseToAnyPublisher()
  
  var cancelable: AnyCancellable?
  cancelable = publisher
    .print()
    .sink { _ in
      if let cancelable {
        subscriptions.remove(cancelable)
      }
    } receiveValue: {
      print("emitted value", $0)
    }
  
  cancelable?.store(in: &subscriptions)
  
  /// Since the publisher is type erased, it cannot use send but only the subject could
  subject.send(0)
  subject.send(1)
  subject.send(2)
  print("current subscriptions: \(subscriptions.count)")
  subject.send(completion: .finished)
  
  print("current subscriptions: \(subscriptions.count)")
}

example(of: "Dynamically adjusting Demand") {
  final class IntSubscriber: Subscriber {
    
    typealias Input = Int
    
    typealias Failure = Never
    
    func receive(subscription: Subscription) {
      subscription.request(.max(2))
    }
    
    func receive(_ input: Int) -> Subscribers.Demand {
      print("Received value", input)
      return switch input {
      case 1:
          .max(2) // original max (2) + new 2 -> 4
      case 3:
          .max(1) // previous 4 + new 1 -> 5
      default:
          .none   // max remain 5 (previous 4 + new 0)
      }
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
      print("Received completion", completion)
    }
    
  }
  
  let subscriber = IntSubscriber()
  
  let subject = PassthroughSubject<Int, Never>()
  
  subject.subscribe(subscriber)
  
  subject.send(1)
  subject.send(2)
  subject.send(3)
  subject.send(4)
  subject.send(5)
  subject.send(6)
}

example(of: "CurrentValueSubject") {
  var subscriptions = Set<AnyCancellable>()
  
  let subject = CurrentValueSubject<Int, Never>(0)
  
  subject
    .print()
    .sink { print("sinking:",$0) }
    .store(in: &subscriptions)
  
  subject.send(1)
  subject.send(2)
  
  /// current value of `CurrentValueSubject` -> it maintance the latest value
  print(subject.value)
  
  /// another way to send value to `CurrentValueSubject`
  subject.value = 3
  print(subject.value)
  
  subject
    .print()
    .sink { print("second subscription:", $0) }
    .store(in: &subscriptions)
  
  subject.send(completion: .finished)
}

example(of: "PassthroughSubject") {
  enum MyError: Error {
    case testError
  }
  
  final class StringSubscriber: Subscriber {
    typealias Input = String
    
    typealias Failure = MyError
    
    func receive(subscription: Subscription) {
      subscription.request(.max(2))
    }
    
    func receive(_ input: String) -> Subscribers.Demand {
      print("Received value", input)
      return input == "World" ? .max(1) : .none
    }
    
    func receive(completion: Subscribers.Completion<MyError>) {
      print("Received completion", completion)
    }
  }
  
  let subscriber = StringSubscriber()
  
  let subject = PassthroughSubject<String, MyError>()
  
  /// Create a subscription by subcribe the subject to subscriber
  subject.subscribe(subscriber)
  
  /// Make another subscription via sink
  let subscription = subject.sink { completion in
    print("Received completion (sink)", completion)
  } receiveValue: { value in
    print("Received value (sink)", value)
  }
  
  subject.send("Hello")
  
  subject.send("World")
  
  /// cancel the subscription to `StringSubscriber`
  subscription.cancel()
  
  subject.send("Still there?")
  
  subject.send(completion: .failure(.testError))
  
  /// finish the subject, after this all the `send` won't emit any value
  subject.send(completion: .finished)
  
  subject.send("How about this?")
}

example(of: "Future") {
  func futureIncrement(
    interger: Int,
    afterDelay delay: TimeInterval
  ) -> Future<Int, Never> {
    Future<Int, Never> { promise in
      DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
        promise(.success(interger + 1))
      }
    }
  }
  
  /// Create a `future`
  let future = futureIncrement(interger: 1, afterDelay: 1)
  
  print("original")
  
  /// Subscribe and print the received value and completion event
  future
    .sink { print($0) } receiveValue: { print($0) }
    .store(in: &subscriptions)
  
  future.sink {
    print("Second", $0)
  } receiveValue: {
    print("Second", $0)
  }
  .store(in: &subscriptions)
  
  subscriptions.removeAll()
}

example(of: "Custom Subscriber") {
  let publisher = (1...6).publisher
  
  /// Custom Subcriber
  final class IntSubScriber: Subscriber {
    /// Define that the input is Int, and never throw error
    typealias Input = Int
    typealias Failure = Never
    
    /// specify that the subscriber is willing to recieve up to 3 values upon subscription
    func receive(subscription: Subscription) {
      subscription.request(.max(3))
    }
    
    ///
    func receive(_ input: Int) -> Subscribers.Demand {
      print("Recieved value:", input)
      return .max(1)
    }
    
    /// completion event
    func receive(completion: Subscribers.Completion<Never>) {
      print("Received completion", completion)
    }
  }
  
  let subscriber = IntSubScriber()
  publisher.subscribe(subscriber)
}

example(of: "assign(to:)") {
  class SomeObject {
    @Published var value = 0
  }
  
  
  let object = SomeObject()
  
  /// use `$` of the `@Published` property gain access to its underlying
  /// publisher, then subcribe to it using sink and print out each value
  object.$value.sink {
    print($0)
  }
  
  /// Create a publisher and assign each value it emits to the `@Published` value of
  /// the object
  (1...10).publisher.assign(to: &object.$value)

}

example(of: "assign(to:, on:)") {
  
  class SomeObject {
    var value: String = "" {
      didSet {
        print(value)
      }
    }
  }
  
  let object = SomeObject()
  
  /// Create publisher from array of string
  let publisher = ["Hello", "world!"].publisher
  
  /// Subcribe to the publisher, assign each value recieved to the value property of `object`
  let sub = publisher.assign(to: \.value, on: object)
  print(subscriptions.count)
  sub.store(in: &subscriptions)
  sub.cancel()
  print(subscriptions.count)
}

example(of: "just") {
  /// create a publisher using `Just`, which create a publisher from a single value
  let just = Just("Hello world!")
  
  _ = just.sink(receiveCompletion: {
    print("Received completion:", $0)
  }, receiveValue: {
    print("Received value:", $0)
  })
  
  /// a `Just` emits it output to each new subcriber exactly once and finishes.
  _ = just.sink(receiveCompletion: {
    print("Received completion (another):", $0)
  }, receiveValue: {
    print("Received value (another):", $0)
  })
}

example(of: "Subscriber") {
  let myNotification = Notification.Name("MyNotification")
  let center = NotificationCenter.default
  
  let publisher = center.publisher(for: myNotification, object: nil)
  
  let subscription = publisher.sink {
    print("Received completion", $0)
  } receiveValue: {
    print("Received value", $0)
  }
  
  center.post(name: myNotification, object: nil)
  
  subscription.cancel()
}

example(of: "publisher") {
  // define the notification name
  let myNotification = Notification.Name("MyNotification")
  
  let center = NotificationCenter.default
  
  // access notification center's and create a publusher for the
  // name we just defined above
  let publisher = center.publisher(for: myNotification, object: nil)
  
  // Create an handle observer to listen to the notification
  let observer = center.addObserver(
    forName: myNotification,
    object: nil,
    queue: nil
  ) { notification in
    print("notification received!")
  }
  
  // post (emit) a notification
  center.post(name: myNotification, object: nil)
  
  // now remove the observer from default notification center
  center.removeObserver(observer)
}

/// Copyright (c) 2021 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.
