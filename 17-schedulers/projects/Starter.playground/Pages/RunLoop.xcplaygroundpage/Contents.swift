import Combine
import SwiftUI
import PlaygroundSupport

var threadRecorder: ThreadRecorder? = nil

let source = Timer
  .publish(every: 1.0, on: .main, in: .common)
  .autoconnect()
  .scan(0) { (counter, _) in counter + 1 }

let setupPublisher = { recorder in
  source
    /// because the `source` is a Timer that run on main thread, even subscribe on `DispatchQueue.global()` -
    /// a concurrent queue but  still return the result as the main thread.
    .subscribe(on: DispatchQueue.global())
    .recordThread(using: recorder)
    .receive(on: RunLoop.current) // The RunLoop that associate with the current thread
    .recordThread(using: recorder)
    .handleEvents(receiveSubscription: { _ in
      threadRecorder = recorder   // capture the recorder
    })
    .eraseToAnyPublisher()
}

let view = ThreadRecorderView(
  title: "Using RunLoop",
  setup: setupPublisher
)

PlaygroundPage.current.liveView = UIHostingController(rootView: view)

RunLoop.current.schedule(
  after: .init(.init(timeIntervalSinceNow: 4.5)),
  tolerance: .milliseconds(500)
) {
  threadRecorder?.subscription?.cancel()
}

//: [Next](@next)
/*:
 Copyright (c) 2023 Kodeco Inc.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 distribute, sublicense, create a derivative work, and/or sell copies of the
 Software in any work that is designed, intended, or marketed for pedagogical or
 instructional purposes related to programming, coding, application development,
 or information technology.  Permission for such use, copying, modification,
 merger, publication, distribution, sublicensing, creation of derivative works,
 or sale is expressly withheld.

 This project and source code may use libraries or frameworks that are
 released under various Open-Source licenses. Use of those libraries and
 frameworks are governed by their own individual licenses.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */
