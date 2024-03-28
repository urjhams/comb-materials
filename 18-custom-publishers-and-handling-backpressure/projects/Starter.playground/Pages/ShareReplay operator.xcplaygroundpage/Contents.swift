import Foundation
import Combine

extension Optional {
  var isNil: Bool {
    switch self {
    case .none:
      true
    case .some(let wrapped):
      false
    }
  }
}

fileprivate 
final class ShareReplaySubscription<Output, Failure: Error> {
  
  /// replay buffer's maximum capacity
  let capacity: Int
  
  var subscriber: AnySubscriber<Output, Failure>? = nil
  
  /// track the accumulated demands the publisher receives from the subscriber
  /// So we can deliver exactly the requested number of values.
  var demand: Subscribers.Demand = .none
  
  /// Store pending values in a buffer until they are either delivered to the subscriber or
  /// throw away.
  var buffer: [Output]
  
  /// keep the potential completion event.
  var completion: Subscribers.Completion<Failure>? = nil
  
  init<S>(
    subscriber: S,
    replay: [Output],
    capacity: Int,
    completion: Subscribers.Completion<Failure>?
  ) where S: Subscriber, Failure == S.Failure, Output == S.Input {
    /// store the subscriber into AnySubscriber
    self.subscriber = AnySubscriber(subscriber)
    self.buffer = replay
    self.capacity = capacity
    self.completion = completion
  }
}

extension ShareReplaySubscription: Subscription {
  func request(_ demand: Subscribers.Demand) {
    if demand != .none {
      self.demand += demand
    }
    emitAsNeeded()
  }
  
  func cancel() {
    complete(with: .finished)
  }
  
  func receive(_ input: Output) {
    guard !subscriber.isNil else {
      return
    }
    
    buffer.append(input)
    
    if buffer.count > capacity {
      buffer.removeFirst()
    }
    
    emitAsNeeded()
  }
  
  func receive(completion: Subscribers.Completion<Failure>) {
    guard let subscriber = subscriber else {
      return
    }
    self.subscriber = nil
    self.buffer.removeAll()
    subscriber.receive(completion: completion)
  }
}

extension ShareReplaySubscription {
  private func complete(with completion: Subscribers.Completion<Failure>) {
    /// declare the local subscriber to keep it if it existed before we clean the subscriber.
    let subscriber = self.subscriber
    
    guard let subscriber else {
      return
    }
    
    self.subscriber = nil
    self.completion = nil
    self.buffer.removeAll()
    
    /// replay the completion event to the subscriber that is keep-ed around.
    subscriber.receive(completion: completion)
    
  }
  
  private func emitAsNeeded() {
    guard let subscriber else {
      return
    }
    
    while demand > .none, !buffer.isEmpty {
      demand -= .max(1)
      ///
      let nextDemand = subscriber.receive(buffer.removeFirst())
      
      if nextDemand != .none {
        demand += nextDemand
      }
      
    }
    
    if let completion {
      complete(with: completion)
    }
  }
}

extension Publishers {
  final class ShareReplay<Upstream: Publisher>: Publisher {
    typealias Output = Upstream.Output
    typealias Failure = Upstream.Failure
    
    private let lock = NSRecursiveLock()
    
    private let upstream: Upstream
    
    private let capacity: Int
    
    private var replay = [Output]()
    
    private var subscriptions = [ShareReplaySubscription<Output, Failure>]()
    
    private var completion: Subscribers.Completion<Failure>? = nil
    
    init(upstream: Upstream, capacity: Int) {
      self.upstream = upstream
      self.capacity = capacity
    }
    
    private func relay(_ value: Output) {
      lock.lock()
      defer {
        lock.unlock()
      }
      
      guard completion.isNil else {
        return
      }
      
      replay.append(value)
      if replay.count > capacity {
        replay.removeFirst()
      }
      
      subscriptions.forEach {
        $0.receive(value)
      }
    }
    
    private func complete(_ completion: Subscribers.Completion<Failure>) {
      lock.lock()
      defer {
        lock.unlock()
      }
      
      self.completion = completion
      
      subscriptions.forEach {
        $0.receive(completion: completion)
      }
    }
    
    func receive<S: Subscriber>(
      subscriber: S
    ) where Upstream.Failure == S.Failure, Upstream.Output == S.Input {
      lock.lock()
      defer {
        lock.unlock()
      }
      
      let subscription = ShareReplaySubscription(
        subscriber: subscriber,
        replay: replay,
        capacity: capacity,
        completion: completion
      )
      
      subscriptions.append(subscription)
      
      subscriber.receive(subscription: subscription)
      
      /// Subscribe only once to the upstream publisher
      guard subscriptions.count == 1 else {
        return
      }
      
      let sink = AnySubscriber(
        receiveSubscription: {
          $0.request(.unlimited)
        }, 
        receiveValue: { [weak self] (value: Output) -> Subscribers.Demand in
          /// relay value that received to downstream subscribers.
          self?.relay(value)
          return .none
        },
        receiveCompletion: { [weak self] in
          /// complete the publisher with the completion event from upstream.
          self?.complete($0)
        }
      )
      
      upstream.subscribe(sink)
    }
    
  }
}

extension Publisher {
  /// convenience operator
  func shareReplay(capacity: Int = .max) -> Publishers.ShareReplay<Self> {
    Publishers.ShareReplay(upstream: self, capacity: capacity)
  }
}

var logger = TimeLogger(sinceOrigin: true)

let subject = PassthroughSubject<Int, Never>()

let publisher = subject.print("shareReplay").shareReplay(capacity: 2)

subject.send(0)

let subscription1 = publisher.sink {
  print("#1 completed: \($0)", to: &logger)
} receiveValue: {
  print("#1 received: \($0)", to: &logger)
}

subject.send(1)
subject.send(2)
subject.send(3)

let subscription2 = publisher.sink {
  print("#2 completed: \($0)", to: &logger)
} receiveValue: {
  print("#2 received: \($0)", to: &logger)
}

subject.send(4)
subject.send(5)
subject.send(completion: .finished)

/// `subscription3` should still receive the last 2 values since the shareReplay has capacity of 2
var subscription3: Cancellable? = nil
DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
  print("subscribing to shareReplay after upstream completed")
  subscription3 = publisher.sink {
    print("#3 completed: \($0)", to: &logger)
  } receiveValue: {
    print("#3 received: \($0)", to: &logger)
  }
}

/*
 even if register the capacity up to 6, `0` will never appear
 since it is emitted before the first subcriber subcribed to the shared publisher
*/
