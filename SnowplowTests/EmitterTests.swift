//
//  EmitterTests.swift
//  SnowplowTests
//
//  Created by Olivier Collet on 2018-04-05.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import XCTest

class EmitterTests: XCTestCase, EmitterDelegate {

    private var emitterExpectation: XCTestExpectation?

    func testEmitter() {
        emitterExpectation = expectation(description: "Success")

        let emitter = Emitter(baseURL: "http://localhost:8080", requestMethod: .post, delegate: self)
        emitter.payloadFlushFrequency = 1

        var payload = Payload(isBase64Encoded: false)
        payload.add(values: [
            .trackerVersion: "swift-test",
            .platform: PlatformName.mobile.rawValue,
            .event: EventType.structured.rawValue
            ])
        emitter.input(payload)

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