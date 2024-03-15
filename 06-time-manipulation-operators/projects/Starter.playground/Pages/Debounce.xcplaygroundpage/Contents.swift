import Combine
import SwiftUI
import PlaygroundSupport

let subject = PassthroughSubject<String, Never>()

/// as the sepcification of debounce, it will emit value after a specific of time between events
let debounced = subject
  // debouce emit an event whenever there are no new event after 1.0 seconds since the latest
  // event
  .debounce(for: .seconds(1.0), scheduler: DispatchQueue.main)
  .share()

let subjectTimeline = TimelineView(title: "Emitted values")
let debouncedTimeline = TimelineView(title: "Deboucned values")

let view = VStack {
  subjectTimeline
  debouncedTimeline
}

PlaygroundPage.current.liveView = UIHostingController(
  rootView: view.frame(width: 375, height: 600)
)

subject.displayEvents(in: subjectTimeline)
debounced.displayEvents(in: debouncedTimeline)

let sub1 = subject.sink { print("+\(deltaTime)s: Subject emitted: \($0)") }

let sub2 = debounced.sink { print("+\(deltaTime)s: Debounced emitted: \($0)") }

subject.feed(with: typingHelloWorld)

/*
 Output:
 
 +0.0s: Subject emitted: H
 +0.1s: Subject emitted: He
 +0.2s: Subject emitted: Hel
 +0.3s: Subject emitted: Hell
 +0.5s: Subject emitted: Hello
 +0.6s: Subject emitted: Hello
 +1.6s: Debounced emitted: Hello
 +2.1s: Subject emitted: Hello W
 +2.2s: Subject emitted: Hello Wo
 +2.2s: Subject emitted: Hello Wor
 +2.5s: Subject emitted: Hello Worl
 +2.5s: Subject emitted: Hello World
 +3.5s: Debounced emitted: Hello World
 
 in 0.6s, the user stop until 2.1s, so between these 2 events, the gap was more than 1 seconds.
 So after 1 seconds (at 1.6s), debouce event is triggered because no subject event was triggered
 in this time.
 The same flow apply with the last emitted element of `subject`. So the debounced still fired up
 because the subject triggered finished (in feed(with:) function) 1.5 seconds after the last value
 was emitted, so at 3.5s, the debouced stillbe triggered. If the finished was emitted before the
 debounce time, there will be no debounce for `Hello World` in this case.
 
 -> When declare deobuce with x (where x is the time interval), after x in time that there is no
 new value is emitted from the upstream publisher, debounce will emit the latest emitted value
 from the upstream publisher.
 
 -> Debounce wait for x from the latest emiited value from the upstream Publisher
*/
//: [Next](@next)
/*:
 Copyright (c) 2021 Razeware LLC
 
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
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

