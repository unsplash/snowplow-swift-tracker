//
//  PayloadTests.swift
//  SnowplowTests
//
//  Created by Olivier Collet on 2018-04-05.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import XCTest

class PayloadTests: XCTestCase {

    func testSetStringValue() {
        // Set the values
        let key = "Key"
        let value = "Value"
        var payload = Payload()

        // Make sure the payload is empty
        XCTAssert(payload[key] == nil)

        // Set the value
        payload.set(value, forKey: key)
        XCTAssert(payload[key] == value)

        // Clear the payload
        payload.set(nil, forKey: key)
        XCTAssert(payload[key] == nil)
    }

    func testSetObjectValue() {
        // Set the values
        let key = "Key"
        let value: [String: Any] = [
            "String": "Value",
            "Int": 1,
            "Object": [
                "String": "Value",
                "Int": 1
            ]
        ]
        var payload = Payload()

        // Make sure the payload is empty
        XCTAssert(payload[key] == nil)

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                XCTFail("Cannot convert JSON object to String.")
                return
            }

            guard let base64String = jsonString.base64Value else {
                XCTFail("Cannot convert to Base64 string.")
                return
            }

            // Set the value using Base64 encoding
            try payload.set(value, forKey: key)
            XCTAssert(payload[key] == base64String)

            // Clear the payload
            payload.set(nil, forKey: key)
            XCTAssert(payload[key] == nil)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSetObjectValueNonBase64Encoded() {
        // Set the values
        let key = "Key"
        let value: [String: Any] = [
            "String": "Value",
            "Int": 1,
            "Object": [
                "String": "Value",
                "Int": 1
            ]
        ]
        var payload = Payload(isBase64Encoded: false)

        // Make sure the payload is empty
        XCTAssert(payload[key] == nil)

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                XCTFail("Cannot convert JSON object to String.")
                return
            }

            // Set the value
            try payload.set(value, forKey: key)
            XCTAssert(payload[key] == jsonString)

            // Clear the payload
            payload.set(nil, forKey: key)
            XCTAssert(payload[key] == nil)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

}
