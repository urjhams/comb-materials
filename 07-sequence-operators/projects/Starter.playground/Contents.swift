import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "reduce") {
  let publisher = [1, 2, 3, 4, 5].publisher
  
  /// 0 here is the starting value of the accumulator
  /// `reduce` is similar to `scan`. But `scan` emit the accumulated value each time a new value
  /// is emitted from the upstream publisher, while `reduce` accumulates the emitted values
  /// until the upstream publisher receive a `.finish`.
  publisher
//    .reduce(0) { $0 + $1 }
    .reduce(0, +)
//    .scan(0, +)
    .sink { print($0) }
    .store(in: &subscriptions)
}

example(of: "allSatisfy") {
  let publisher = stride(from: 0, to: 5, by: 2).publisher
  
  publisher
    .print("publisher")
    .allSatisfy { $0 % 2 == 0 }
    .sink { print($0 ? "all are multipled to 2" : "Not all are multipled to 2") }
    .store(in: &subscriptions)
}

example(of: "contains(where:)") {
  struct Person {
    let id: Int
    let name: String
  }
  
  let peoplePublisher = [(123, "Shai Mishali"), (777, "Marin Todorov"), (214, "Florent Pillet")]
    .map(Person.init)
    .publisher
  
  peoplePublisher
    .contains { $0.id == 214 }
    .sink { print($0 ? "Criteria matches!" : "Couldn't find a match for the criteria") }
    .store(in: &subscriptions)
}

example(of: "contains") {
  let publisher = ["A", "B", "C", "D", "E"].publisher
  
  let letter = "C"
  
  publisher
    .print("publisher")
    .contains(letter)
    .sink {
      print($0 ? "Publisher emitted \(letter)!" : "Publisher never emitted \(letter)!")
    }
}

example(of: "count") {
  let publisher = ["A", "B", "C"].publisher
  
  publisher
    .print("publisher")
    .count()
    .sink { print("the number of emitted values is", $0) }
    .store(in: &subscriptions)
}

example(of: "output(in:)") {
  let publisher = ["A", "B", "C", "D", "E"].publisher
  
  publisher
    .output(in: 1...3)
    .sink { print($0) } receiveValue: { print("The value from range 1 to 3 is", $0) }
    .store(in: &subscriptions)
}

example(of: "output(at:)") {
  let publisher = ["A", "B", "C", "D", "E"].publisher
  
  let position = 4
  
  publisher
    .print("publisher")
    .output(at: position - 1)
    .sink { print("The emiteed value at position \(position) is", $0) }
    .store(in: &subscriptions)
}

example(of: "last") {
  let publisher = ["A", "B", "C"].publisher
  
  publisher
    .print("publisher")
    .last()
    .sink { print("Last value is", $0) }
    .store(in: &subscriptions)
}

example(of: "first(where:)") {
  let publisher = ["J", "O", "H", "N"].publisher
  
  publisher
    .print("publisher")
    .first { "Hello World".lowercased().contains($0.lowercased()) }
    .sink { print("The first match is", $0) }
    .store(in: &subscriptions)
}

example(of: "first") {
  let publisher = ["A", "B", "C"].publisher
  
  publisher
    .print("publisher")
    .first()
    .sink { print("First value is", $0) }
    .store(in: &subscriptions)
}

example(of: "max") {
  let publisher = ["A", "F", "Z", "E"].publisher
  
  publisher
    .print("publisher")
    .max()
    .sink { print("Highest value is", $0) }
    .store(in: &subscriptions)
}

example(of: "min - non comparable") {
  let publisher = ["12345", "ab", "hello world"]
    .map { Data($0.utf8) }
    .publisher
  
  publisher
    .print("publisher")
    .min { $0.count < $1.count }
    .sink {
      let string = String(data: $0, encoding: .utf8)!
      print("smallest data is \(string), \($0.count) bytes")
    }
    .store(in: &subscriptions)
}


example(of: "min") {
  let publisher = [1, -50, 246, 0].publisher
  
  publisher
    .print("publisher")
    .min()
    .sink { print("lowest value is", $0) }
    .store(in: &subscriptions)
}
