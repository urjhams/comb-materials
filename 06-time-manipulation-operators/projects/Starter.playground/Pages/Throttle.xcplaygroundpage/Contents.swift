import Combine
import SwiftUI
import PlaygroundSupport

let throttleDelay = 1.0

let subject = PassthroughSubject<String, Never>()

/// The throttle only emit the first value it received from subject during each 1 second
/// because the `latest` is `false`
let throttled = subject
  .throttle(for: .seconds(throttleDelay), scheduler: DispatchQueue.main, latest: true)
  .share()

let subjectTimeline = TimelineView(title: "Emitted values")
let throttledTimeline = TimelineView(title: "Throlled values")

let view = VStack {
  subjectTimeline
  throttledTimeline
}

PlaygroundPage.current.liveView = UIHostingController(
  rootView: view.frame(width: 375, height: 600)
)

subject.displayEvents(in: subjectTimeline)
throttled.displayEvents(in: throttledTimeline)

let sub1 = subject.sink { print("+\(deltaTime)s: Subject emitted: \($0)") }

let sub2 = throttled.sink { print("+\(deltaTime)s: Throttled emitted: \($0)") }

subject.feed(with: typingHelloWorld)

/*
 Output:
 +0.0s: Subject emitted: H
 +0.0s: Throlled emitted: H
 +0.1s: Subject emitted: He
 +0.2s: Subject emitted: Hel
 +0.3s: Subject emitted: Hell
 +0.5s: Subject emitted: Hello
 +0.6s: Subject emitted: Hello
 +1.0s: Throlled emitted: He
 +2.1s: Subject emitted: Hello W
 +2.1s: Throlled emitted: Hello W
 +2.2s: Subject emitted: Hello Wo
 +2.2s: Subject emitted: Hello Wor
 +2.5s: Subject emitted: Hello Worl
 +2.5s: Subject emitted: Hello World
 +3.1s: Throlled emitted: Hello Wo
 
 -> If define a throttle with x (where x is time interval), then throttle will trigger each every x
 in time and emit the first value that the upstream publisher emitted in that time frame (x).
 -> Throttle wait for x, and track the first emitted value from the upstream publisher if the
 `latest` parameter is set to `false`
 -> if `latest` parameter is set to `true`, Throttle will track to the last emitted value in x time
 frame instead.
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

