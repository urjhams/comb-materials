//: [Previous](@previous)
import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()
//: ## Designing your fallible APIs
example(of: "Joke API") {
  class DadJokes {
    struct Joke: Decodable {
      let id: String
      let joke: String
    }
    
    enum Error: Swift.Error, CustomStringConvertible {
      case network
      case jokeDoesntExist(id: String)
      case parsing
      case unknown
      
      var description: String {
        switch self {
        case .network:
          "Request to API Server failed."
        case .jokeDoesntExist(let id):
          "Joke with id \(id) doesn't exist"
        case .parsing:
          "Failed parsing response from server"
        case .unknown:
          "An unknown error occurred"
        }
      }
    }
    
    func getJoke(_ id: String) -> AnyPublisher<Joke, Error> {
      
      // id must at least contain one letter
      guard id.rangeOfCharacter(from: .letters) != nil else {
        return Fail<Joke, Error>(error: .jokeDoesntExist(id: id))
          .eraseToAnyPublisher()
      }
      
      let url = URL(string: "https://icanhazdadjoke.com/j/\(id)")!
      var request = URLRequest(url: url)
      request.allHTTPHeaderFields = ["Accept": "application/json"]
      
      return URLSession.shared
        .dataTaskPublisher(for: request)
        .tryMap { data, response -> Data in
          guard 
            let object = try? JSONSerialization.jsonObject(with: data),
            let dictionary = object as? [String: Any],
            dictionary["status"] as? Int == 404
          else {
            return data
          }
          
          throw DadJokes.Error.jokeDoesntExist(id: id)
        }
        .decode(type: Joke.self, decoder: JSONDecoder())
        .mapError { error -> DadJokes.Error in
          switch error {
          case is URLError:
            .network
          case is DecodingError:
            .parsing
          default:
            error as? DadJokes.Error ?? .unknown
          }
        }
        .eraseToAnyPublisher()
    }
  }
  
  let api = DadJokes()
  let jokeId = "9prWnjyImyd"
  let badJokeID = "123456"
  
  api.getJoke(jokeId)
    .sink { print($0) } receiveValue: { print("Got joke:", $0) }
    .store(in: &subscriptions)
}
//: [Next](@next)

/// Copyright (c) 2023 Kodeco Inc.
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
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.
