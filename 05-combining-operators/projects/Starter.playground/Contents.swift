import UIKit
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "zip") {
  let publisher1 = PassthroughSubject<Int, Never>()
  let publisher2 = PassthroughSubject<String, Never>()
  
  publisher1
    .zip(publisher2)
    .sink { print($0) } receiveValue: { print("P1: \($0), P2: \($1)") }
    .store(in: &subscriptions)
  
  publisher1.send(1)
  publisher1.send(2)
  publisher2.send("a")
  publisher2.send("b")
  publisher1.send(3)
  publisher2.send("c")
  publisher2.send("d")
  
  publisher1.send(completion: .finished)
  publisher2.send(completion: .finished)
}

example(of: "combineLatest") {
  let publisher1 = PassthroughSubject<Int, Never>()
  let publisher2 = PassthroughSubject<String, Never>()
  
  publisher1
    .combineLatest(publisher2)
    .sink { print($0) } receiveValue: { print("P1: \($0), P2: \($1)") }
    .store(in: &subscriptions)
  
  publisher1.send(1)
  publisher1.send(2)
  
  publisher2.send("a")
  publisher2.send("b")
  
  publisher1.send(3)
  
  publisher2.send("c")
  
  publisher1.send(completion: .finished)
  publisher2.send(completion: .finished)
}

example(of: "merge(with:)") {
  let publisher1 = PassthroughSubject<Int, Never>()
  let publisher2 = PassthroughSubject<Int, Never>()
  
  publisher1.merge(with: publisher2)
    .sink { _ in print("Completed") } receiveValue: { print($0) }
    .store(in: &subscriptions)
  
  publisher1.send(1)
  publisher1.send(2)
  
  publisher2.send(3)
  
  publisher1.send(4)
  
  publisher2.send(5)
  
  publisher1.send(completion: .finished)
  publisher2.send(completion: .finished)
}

example(of: "switchToLastest - realife scenario - Network Request") {
  guard let url = URL(string: "https://source.unsplash.com/random") else {
    return
  }
  
  func getImage() -> AnyPublisher<UIImage?, Never> {
    URLSession.shared
      .dataTaskPublisher(for: url)
      .map { data, _ in UIImage(data: data) }
      .print("image")
      .replaceError(with: nil)
      .eraseToAnyPublisher()
  }
  
  let taps = PassthroughSubject<Void, Never>()
  
  taps
    .map { _ in getImage() }  // when tap, create new network reqeust
    .switchToLatest() //automatically cancel the leftover subscriptions
    .sink { _ in }
    .store(in: &subscriptions)
  
  taps.send()
  
  DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
    taps.send()
  }
  
  /// Since this tap send is just 0.01 second after the previous tap, the previous tap will be cancelled
  /// as the task is switched to the latest task for this `send` event.
  DispatchQueue.main.asyncAfter(deadline: .now() + 3.01) {
    taps.send()
  }
}

example(of: "switchToLatest") {
  let publisher1 = PassthroughSubject<Int, Never>()
  let publisher2 = PassthroughSubject<Int, Never>()
  let publisher3 = PassthroughSubject<Int, Never>()
  
  let publishers = PassthroughSubject<PassthroughSubject<Int, Never>, Never>()
  
  publishers
    .switchToLatest()
    .sink { _ in print("Completed") } receiveValue: { print($0) }
    .store(in: &subscriptions)
  
  publishers.send(publisher1)
  publisher1.send(1)
  publisher1.send(2)
  
  publishers.send(publisher2)
  publisher1.send(3)  // at this point, publishers switched to publisher2 already
  publisher2.send(4)
  publisher2.send(5)
  
  publishers.send(publisher3)
  publisher2.send(6)  // at this point, publishers switched to publisher3 already
  publisher3.send(7)
  publisher3.send(8)
  publisher3.send(9)
  
  publisher3.send(completion: .finished)
  publishers.send(completion: .finished)
}

example(of: "append(Publisher)") {
  let publisher1 = [1, 2].publisher
  let publisher2 = [3, 4].publisher
  
  publisher1
    .append(publisher2)
    .sink { print($0) }
    .store(in: &subscriptions)
  
  print("scenario #2")
  
  let publisher = PassthroughSubject<Int, Never>()
  publisher
    .append(publisher1)
    .sink { print($0) }
    .store(in: &subscriptions)
  
  publisher.send(-1)
  publisher.send(0)
  
  /// publisher must be finished so the publisher1 can emit its values and be appended
  publisher.send(completion: .finished)
}

example(of: "append(Sequence)") {
  let publisher = [1, 2, 3].publisher
  
  publisher
    .append([4, 5])
    .append(Set([6,7]))
    .append(stride(from: 8, to: 13, by: 2))
    .sink { print($0) }
    .store(in: &subscriptions)
}

example(of: "append(Output...)") {
  let publisher = [1].publisher
  
  publisher
    .append(2, 3)
    .append(4)
    .sink { print($0) }
    .store(in: &subscriptions)
  
  print("scenario 2")
  let publisher2 = PassthroughSubject<Int, Never>()
  
  publisher2
    .append(2, 3)
    .sink { print($0) }
    .store(in: &subscriptions)
  
  publisher2.send(1)
  
  /// publisher2 must send the completion .finished so the append could be triggered.
  publisher2.send(completion: .finished)
}

example(of: "prepend(Publisher) #2") {
  let publisher1 = [3, 4].publisher
  let publisher2 = PassthroughSubject<Int, Never>()
  
  publisher1
    .prepend(publisher2)
    .sink { print($0) }
    .store(in: &subscriptions)
  
  publisher2.send(1)
  publisher2.send(2)
  
  /// Since we prepend publisher2 to publisher1, publisher2 must befinished before
  /// the publisher1's value can be emitted.
  publisher2.send(completion: .finished)
}

example(of: "prepend(Publisher)") {
  let publisher1 = [3, 4].publisher
  let publisher2 = [1, 2].publisher
  
  /// publisher1 will emit after the values from publisher2 are emitted and finished
  publisher1
    .prepend(publisher2)
    .sink { print($0) }
    .store(in: &subscriptions)
}

example(of: "prepend(Sequence)") {
  let publisher = [8, 9, 10].publisher
  
  /// use prepend(Sequence) to add value fron a sequence before the publisher emits it own values
  publisher
    .prepend([6, 7])
    .prepend(Set(1...5))  // use Set won't guarantee the order (of course)
    .prepend(stride(from: 6, through: 11, by: 2)) // `stridable` also conform `Sequence`
    .sink { print($0) }
    .store(in: &subscriptions)
}

example(of: "prepend(Output...)") {
  let publisher = [3, 4].publisher
  
  /// use `prepend` to add values before the publisher emit it own values
  publisher
    .prepend(1, 2)  // this prepend affect the upstream first
    .prepend(-1, 0) // then this prepend affect after so we keep the right order
    .sink { print($0) }
    .store(in: &subscriptions)
}
