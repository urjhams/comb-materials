import Combine
import SwiftUI
import PlaygroundSupport

enum TimeoutError: Error {
  case timeOut
}

//let subject = PassthroughSubject<Void, Never>()
//
///// timeout will either complete a publisher or emit an error after an amount of time
//let timeoutPublisher = subject.timeout(.seconds(5), scheduler: DispatchQueue.main)

let subject = PassthroughSubject<Void, TimeoutError>()

/// timeout will either complete a publisher or emit an error after an amount of time
let timeoutPublisher = subject.timeout(.seconds(5), scheduler: DispatchQueue.main) { .timeOut }


let timeline = TimelineView(title: "Button taps")

let view = VStack {
  Button { subject.send() } label: { Text("Press me within 5 seconds") }
  
  timeline
}

PlaygroundPage.current.liveView = UIHostingController(
  rootView: view.frame(width: 375, height: 600)
)

timeoutPublisher.displayEvents(in: timeline)
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

