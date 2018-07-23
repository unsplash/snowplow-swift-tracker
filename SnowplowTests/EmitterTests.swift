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

        let emitter = Emitter(baseURL: "http://localhost:3000", requestMethod: .post, delegate: self)

        let payload = Payload(values: ["TestKey": "Test Value"])
        for _ in 0..<10 {
            emitter.send(payload)
        }

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
