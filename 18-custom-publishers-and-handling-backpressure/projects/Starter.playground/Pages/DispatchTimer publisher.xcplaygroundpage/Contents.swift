import Foundation
import Combine

struct DispatchTimerConfiguration {
  /// the timer is able on a certain queue
  let queue: DispatchQueue?
  
  /// The interval at which the timer fires, starting from the subscription time
  let interval: DispatchTimeInterval
  
  /// The maximum amount of time after the deadline the system may delivery of the timer event
  let leeway: DispatchTimeInterval
  
  /// The number of timer events to receive
  let times: Subscribers.Demand
}

extension Publishers {
  struct DispatchTimer: Publisher {
    
    typealias Output = DispatchTime
    
    typealias Failure = Never
    
    let configuration: DispatchTimerConfiguration
    
    init(configuration: DispatchTimerConfiguration) {
      self.configuration = configuration
    }
    
    func receive<S>(
      subscriber: S
    ) where S : Subscriber, Never == S.Failure, DispatchTime == S.Input {
      let subscription = DispatchTimerSubscription(
        subscriber: subscriber,
        configuration: configuration
      )
      
      subscriber.receive(subscription: subscription)
    }
  }
  
  private final class DispatchTimerSubscription<S: Subscriber>: Subscription where S.Input == DispatchTime {
    
    let configuration: DispatchTimerConfiguration
    
    var times: Subscribers.Demand
    
    var requested: Subscribers.Demand = .none
    
    var source: DispatchSourceTimer? = nil
    
    var subscriber: S?
    
    init(subscriber: S, configuration: DispatchTimerConfiguration) {
      self.configuration = configuration
      self.subscriber = subscriber
      self.times = configuration.times
    }
    
    func request(_ demand: Subscribers.Demand) {
      guard times > .none else {
        subscriber?.receive(completion: .finished)
        return
      }
      
      requested += demand
      
      /// if there is no timer existed  but there is a request, it's time ti start the timer
      if source == nil, requested > .none {
        let source = DispatchSource
          .makeTimerSource(queue: configuration.queue)
        
        /// Schedule the timer to fire after every `configuration.interval` seconds.
        source.schedule(
          deadline: .now() + configuration.interval,
          repeating: configuration.interval,
          leeway: configuration.leeway
        )
        
        source.setEventHandler { [weak self] in
          guard let self, requested > .none else {
            return
          }
          
          /// decrment  both counters that we are going to emit a value
          requested -= .max(1)
          times -= .max(1)
          
          /// send the value to the subscriber
          _ = subscriber?.receive(.now())
          
          /// if the `times` reached to the end of its cap, then send the `finished` completion event
          if times == .none {
            subscriber?.receive(completion: .finished)
          }
        }
        
        /// assign and active the timer.
        self.source = source
        source.activate()
      }
    }
    
    func cancel() {
      source = nil
      subscriber = nil
    }
  }
}

extension Publishers {
  static func timer(
    queue: DispatchQueue? = nil,
    interval: DispatchTimeInterval,
    leeway: DispatchTimeInterval = .nanoseconds(0),
    times: Subscribers.Demand = .unlimited
  ) -> Publishers.DispatchTimer {
    Publishers.DispatchTimer(
      configuration: .init(
        queue: queue, 
        interval: interval,
        leeway: leeway,
        times: times
      )
    )
  }
}

var logger = TimeLogger(sinceOrigin: true)

// time publisher fires 6 times in each 1 second
let publisher = Publishers.timer(
  interval: .seconds(1), times: .max(6)
)

let subscription = publisher.sink {
  print("Tomer emits: \($0)", to: &logger)
}

DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
  subscription.cancel()
}
