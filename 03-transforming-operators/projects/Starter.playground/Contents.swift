import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "scan") {
  var dailyGainLoss: Int {
    .random(in: -10...10)
  }
  
  let march2023 = (0..<30)
    .map { _ in dailyGainLoss }
    .publisher
  
  march2023.scan(50) { latest, current in
    max(0, latest + current)
  }
  .sink { _ in
    
  }
  .store(in: &subscriptions)
}

example(of: "replaceEmpty(with:)") {
  let empty = Empty<Int, Never>()
  
  empty
    .replaceEmpty(with: 3)
    .sink { print($0) } receiveValue: { print($0) }
    .store(in: &subscriptions)
}

example(of: "replaceNil") {
  ["A", nil, "C"].publisher
    .eraseToAnyPublisher()
    .replaceNil(with: "-")
    .sink { print($0) }
    .store(in: &subscriptions)
}

example(of: "FlatMap") {
  func decoding(_ codes: [Int]) -> AnyPublisher<String, Never> {
    Just(
      codes
        .compactMap { code in
          guard (32...255).contains(code) else {
            return nil
          }
          return String(UnicodeScalar(code) ?? " ")
        }
        .joined()
    )
    .eraseToAnyPublisher()
  }
  
  let collected = [72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33]
    .publisher
    .collect()
    
  let publisher = collected.flatMap(decoding)
  
  publisher
    .sink { print($0) }
    .store(in: &subscriptions)
  
  [1, 2, 3].publisher.flatMap { value in
    (0..<value).publisher.print()
  }
  .sink { value in
    print("value:", value)
  }
  .store(in: &subscriptions)
}

example(of: "tryMap") {
  let just = Just("Directory name that does not exist")
    .tryMap { try FileManager.default.contentsOfDirectory(atPath: $0) }
    
  just
    .sink { print($0) } receiveValue: { print($0) }
    .store(in: &subscriptions)
}

example(of: "Mapping key paths") {
  let publisher = PassthroughSubject<Coordinate, Never>()
  
  publisher
    .map(\.x, \.y)
    .sink { x, y in
      print(
        "The coordinate at (\(x), \(y)) is in quuadrant", quadrantOf(x: x, y: y)
      )
    }
    .store(in: &subscriptions)
  
  publisher.send(.init(x: 10, y: -8))
  publisher.send(Coordinate(x: 0, y: 5))
}

example(of: "Map") {
  let formatter = NumberFormatter()
  formatter.numberStyle = .spellOut
  
  [123, 4, 56].publisher
    .map { number in
      formatter.string(for: NSNumber(integerLiteral: number)) ?? ""
    }
    .sink { print($0) }
    .store(in: &subscriptions)
}

example(of: "Collect") {
  ["A", "B", "C", "D", "E"].publisher
    .print()
    .collect(2)
    .sink {
      print($0)
    } receiveValue: {
      print("🙆🏻", $0)
    }
    .store(in: &subscriptions)

}
