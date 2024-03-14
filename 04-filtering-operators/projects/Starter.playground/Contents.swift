import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "prefix(untilOutputFrom:)") {
  let isReady = PassthroughSubject<Void, Never>()
  let taps = PassthroughSubject<Int, Never>()
  
  /// using prefix, we receive the emitted values from taps until isReady is sent
  taps
    .prefix(untilOutputFrom: isReady)
    .sink { print($0) }
    .store(in: &subscriptions)
  
  (1...5).forEach {
    taps.send($0)
    
    if $0 == 3 {
      isReady.send()
    }
  }
}

example(of: "prefix(while:)") {
  let numbers = (1...10).publisher
  
  numbers
    .prefix { $0 < 5 }
    .sink { print("Completed with:", $0) } receiveValue: { print($0) }
    .store(in: &subscriptions)
}

example(of: "prefix") {
  let numbers = (1...10).publisher
  
  numbers
    .prefix(2)
    .sink { print("Completed with:", $0) } receiveValue: { print($0) }
    .store(in: &subscriptions)
}

example(of: "drop(untilOutputFrom:)") {
  let isReady = PassthroughSubject<Void, Never>()
  let taps = PassthroughSubject<Int, Never>()
  
  taps
    .drop(untilOutputFrom: isReady)
    .sink { print($0) }
    .store(in: &subscriptions)
  
  (1...5).forEach {
    taps.send($0)
    
    if $0 == 3 {
      isReady.send()
    }
  }
}

example(of: "dropFist") {
  let numbers = (1...10).publisher
  
  numbers
    .dropFirst(8)
    .sink { print($0) }
    .store(in: &subscriptions)
  
  print("using drop(while:)")
  numbers
    .drop { $0 % 5 != 0 }
    .sink { print($0) }
    .store(in: &subscriptions)
}

example(of: "last(where:)") {
  let numbers = (1...9).publisher
  
  numbers
    .print("numbers")
    .last { $0 % 2 == 0 }
    .sink { print("Completed with:", $0) } receiveValue: { print($0) }
    .store(in: &subscriptions)
  
  let subjects = PassthroughSubject<Int, Never>()
  
  subjects
    .last { $0 % 2 == 0 }
    .sink { print("Completed with:", $0) } receiveValue: { print($0) }
    .store(in: &subscriptions)
  
  subjects.send(1)
  subjects.send(2)
  subjects.send(3)
  subjects.send(4)
  subjects.send(5)
  
  /// The  `last(where:)` require the publisher need to complete emitting values to know the last
  /// value that match the criteria.
  subjects.send(completion: .finished)
}

example(of: "first(where:)") {
  let numbers = (1...9).publisher
  
  /// as soon as the first value is triggered, the subscription will receive cancelled
  numbers
    .print("numbers")
    .first { $0 % 2 == 0 }
    .sink { print("completed with:", $0) } receiveValue: { print($0) }
    .store(in: &subscriptions)
}

example(of: "Ignore output") {
  let numbers = (1...10_000).publisher
  
  /// Use `ignoreOutput()` to ignore all the emited values
  numbers
    .ignoreOutput()
    .sink { print("Completed with:", $0) } receiveValue: { print($0) }
    .store(in: &subscriptions)
}

example(of: "Compact map") {
  let strings = ["a", "1.24", "3", "def", "45", "0.23"].publisher
  
  /// Compact map will ignore the nil value while mapping so if the string is unable to turned into a floating point
  /// number, then it will be nil and be ignored.
  strings
    .compactMap(Float.init)
    .sink { print($0) }
    .store(in: &subscriptions)
}

example(of: "remove duplicates") {
  let words = "hey hey there! Want to listen to mister mister ?"
    .components(separatedBy: " ")
    .publisher
  
  words
    .removeDuplicates()
    .sink { print($0) }
    .store(in: &subscriptions)
}


example(of: "filter") {
  let numbers = (1...10).publisher
  
  numbers
    .filter { $0.isMultiple(of: 3) }
    .sink { print("\($0) is a multiple of 3!") }
    .store(in: &subscriptions)
}
