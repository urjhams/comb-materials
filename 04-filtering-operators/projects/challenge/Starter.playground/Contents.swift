import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "Challenge") {
  // collection of number from 1 to 100 publisher
  let publisher = (1...100).publisher
  
  publisher
  // skip the first 50 values by the upstream publisher
    .dropFirst(50)
  // take the next 20 values
    .prefix(20)
  // only take even number
    .filter { $0 % 2 == 0 }
    .sink { print($0) }
    .store(in: &subscriptions)
}
