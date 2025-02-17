//
//  TrackerTests.swift
//  SnowplowTests
//
//  Created by Olivier Collet on 2018-06-07.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import XCTest

class TrackerTests: XCTestCase, EmitterDelegate {

  private var emitterExpectation: XCTestExpectation?

  private lazy var tracker: Tracker = {
    let emitter = Emitter(baseURL: "http://localhost:8080", requestMethod: .post, delegate: self)
    emitter.payloadFlushFrequency = 1

    return Tracker(applicationId: "swift-test-app",
                   emitter: emitter,
                   name: "test")
  }()

  func testTrackPageView() {
    emitterExpectation = expectation(description: "Success")

    tracker.trackPageView(uri: "test-page")

    waitForExpectations(timeout: 10) { (error) in
      if let error = error {
        debugPrint(error)
      }
    }
  }

  func testTrackStructEvent() {
    emitterExpectation = expectation(description: "Success")

    tracker.trackStructEvent(category: "test-category", action: "test-action")

    waitForExpectations(timeout: 10) { (error) in
      if let error = error {
        debugPrint(error)
      }
    }
  }

  // MARK: - Emitter delegate

  func emitter(_ emitter: Emitter, didFlush success: Bool) {
    emitterExpectation?.fulfill()
  }

}
