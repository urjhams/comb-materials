import Combine
import Foundation

protocol Pausable {
  var paused: Bool { get }
  func resume()
}

final class PausableSubscriber<Input, Failure: Error>: Subscriber, Pausable, Cancellable {
  let combineIndentifier = CombineIdentifier()
  
  /// `true` indicates  that it may receive more values and `false` indicates the subscription should pause.
  let receiveValue: (Input) -> Bool
  
  /// will be called upon receiving a completion event from the publisher
  let receiveCompletion: (Subscribers.Completion<Failure>) -> Void
  
  /// keep the subscription around so that it can request more values after a papuse.
  /// Set to nil when don't need to avoid retain cycle.
  private var subscription: Subscription? = nil
  
  /// expise this as per Pausable protocol
  var paused = false
  
  init(
    receiveValue: @escaping (Input) -> Bool,
    receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void
  ) {
    self.receiveValue = receiveValue
    self.receiveCompletion = receiveCompletion
  }
  
  func cancel() {
    subscription?.cancel()
    subscription = nil
  }
  
  func receive(subscription: any Subscription) {
    /// Upon receiving the subscription created by the publisher, store it for later so that we are able to resume from a pause
    self.subscription = subscription
    
    /// Request value one by one since it pausable and we can't predict when a pause will be needed.
    subscription.request(.max(1))
  }
  
  func receive(_ input: Input) -> Subscribers.Demand {
    paused = !receiveValue(input)
    
    return paused ? .none : .max(1)
  }
  
  func receive(completion: Subscribers.Completion<Failure>) {
    /// foward the completion event and clear up the subscription
    receiveCompletion(completion)
    subscription = nil
  }
  
  func resume() {
    guard paused else {
      return
    }
    
    paused = false
    
    /// If the publisher is `paused`, request one vallue the start the cycle
    subscription?.request(.max(1))
  }
}

extension Publisher {
  func pausableSink(
    receiveCompletion: @escaping ((Subscribers.Completion<Failure>) -> Void),
    receiveValue: @escaping ((Output) -> Bool)
  ) -> Pausable & Cancellable {
    
    let pausable = PausableSubscriber(
      receiveValue: receiveValue,
      receiveCompletion: receiveCompletion
    )
    
    subscribe(pausable)
    
    return pausable
  }
}

let subscription = [1, 2, 3, 4, 5, 6]
  .publisher
  .pausableSink { completion in
    print("Pausable subscription completed:", completion)
  } receiveValue: { value in
    print("receive value:", value)
    if value % 2 == 1 {
      print("pausing")
      return false
    }
    return true
  }

let timer = Timer.publish(every: 1, on: .main, in: .common)
  .autoconnect()
  .sink { _ in
    guard subscription.paused else {
      return
    }
    print("sibscription is paused, resuming")
    subscription.resume()
  }
