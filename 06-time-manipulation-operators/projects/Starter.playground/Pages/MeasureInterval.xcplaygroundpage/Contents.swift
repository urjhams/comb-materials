import Combine
import SwiftUI
import PlaygroundSupport

let subject = PassthroughSubject<String, Never>()

let measurePublisher = subject.measureInterval(using: DispatchQueue.main)

let measurePublisher2 = subject.measureInterval(using: RunLoop.main)

let subjectTimeline = TimelineView(title: "Emitted values")
let measuredTimeline = TimelineView(title: "Measured values")
let measured2Timeline = TimelineView(title: "Measured values (2)")

let view = VStack {
  subjectTimeline
  measuredTimeline
  measured2Timeline
}

PlaygroundPage.current.liveView = UIHostingController(
  rootView: view.frame(width: 375, height: 600)
)

subject.displayEvents(in: subjectTimeline)
measurePublisher.displayEvents(in: measuredTimeline)
measurePublisher2.displayEvents(in: measured2Timeline)

let sub1 = subject.sink { print("+\(deltaTime)s: Subject emitted: \($0)") }

let sub2 = measurePublisher.sink {
  print("+\(deltaTime)s: Measure emitted: \(Double($0.magnitude) / 1_000_000_000.0)")
}

let sub3 = measurePublisher2.sink {
  print("+\(deltaTime)s: Measure2 emitted: \($0)")
}

subject.feed(with: typingHelloWorld)
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

