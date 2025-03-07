import Foundation
import PlaygroundSupport
import Combine

struct API {
  /// API Errors.
  enum Error: LocalizedError {
    case addressUnreachable(URL)
    case invalidResponse
    
    var errorDescription: String? {
      switch self {
      case .invalidResponse: return "The server responded with garbage."
      case .addressUnreachable(let url): return "\(url.absoluteString) is unreachable."
      }
    }
  }
  
  /// API endpoints.
  enum EndPoint {
    static let baseURL = URL(string: "https://hacker-news.firebaseio.com/v0/")!
    
    case stories
    case story(Int)
    
    var url: URL {
      switch self {
      case .stories:
        return EndPoint.baseURL.appendingPathComponent("newstories.json")
      case .story(let id):
        return EndPoint.baseURL.appendingPathComponent("item/\(id).json")
      }
    }
  }

  /// Maximum number of stories to fetch (reduce for lower API strain during development).
  var maxStories = 10

  /// A shared JSON decoder to use in calls.
  private let decoder = JSONDecoder()
  
  private let apiQueue = DispatchQueue(
    label: "API",
    qos: .default,
    attributes: .concurrent
  )
  
  func story(_ id: Int) -> AnyPublisher<Story, Error> {
    URLSession
      .shared
      .dataTaskPublisher(for: EndPoint.story(id).url)
      .receive(on: apiQueue)
      .map(\.data)
      .decode(type: Story.self, decoder: decoder)
      .catch { _ in Empty<Story, Error>() } // ignore error and return empty
      .eraseToAnyPublisher()
  }
  
  func mergedStories(ids: [Int]) -> AnyPublisher<Story, Error> {
    let storyIds = Array(ids.prefix(maxStories))
    
    precondition(!storyIds.isEmpty)
    
    let initialPublisher = story(storyIds[0])
    let remainder = Array(storyIds.dropFirst())
    
    return remainder.reduce(initialPublisher) { combined, id in
      combined
        .merge(with: story(id))
        .eraseToAnyPublisher()
    }
  }
  
  func mergedStories(of ids: Int...) -> AnyPublisher<Story, Error> {
    mergedStories(ids: ids)
  }
  
  func stories() -> AnyPublisher<[Story], Error> {
    URLSession
      .shared
      .dataTaskPublisher(for: EndPoint.stories.url)
      .receive(on: apiQueue)
      .map(\.data)
      .decode(type: [Int].self, decoder: decoder)
      .mapError { error in
        switch error {
        case is URLError:
          Error.addressUnreachable(EndPoint.stories.url)
        default:
          Error.invalidResponse
        }
      }
      .filter { !$0.isEmpty }
      // since mapping each `mergedStories(ids:)` are Publishers, use flatMap
      // to flatten them into a single downstream Publisher
      .flatMap(self.mergedStories(ids:))
      // use `scan` so we have an accumulator of stories, and keep appending it
      // whenever there is a new story returned
      .scan([]) { stories, story in stories + [story] }
      .map { $0.sorted() }
      .eraseToAnyPublisher()
  }
}

let api = API()

var subscription = Set<AnyCancellable>()

//api.story(999)
//  .sink { print($0) } receiveValue: { print($0) }
//  .store(in: &subscription)
//
//api.mergedStories(of: 1000, 1001, 1002)
//  .sink { print($0) } receiveValue: { print($0) }
//  .store(in: &subscription)

api.stories()
  .sink { print($0) } receiveValue: { print($0) }
  .store(in: &subscription)


// Run indefinitely.
PlaygroundPage.current.needsIndefiniteExecution = true

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
