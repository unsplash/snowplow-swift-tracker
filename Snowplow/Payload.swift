//
//  Payload.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-04-05.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation

struct Payload {

    init(isBase64Encoded: Bool = true) {
        self.isBase64Encoded = isBase64Encoded
    }

    mutating func add(values: [PropertyKey: String]) {
        self.values.merge(values, uniquingKeysWith: { (current, _) in current })
    }

    mutating func set(_ value: String, forKey key: PropertyKey) {
        self.values[key] = value
    }

    mutating func set(_ object: Any?, forKey key: PropertyKey) throws {
        guard let object = object else {
            values.removeValue(forKey: key)
            return
        }

        let jsonData = try JSONSerialization.data(withJSONObject: object, options: [])

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw PayloadError.convertionFailed
        }

        if isBase64Encoded == false {
            set(jsonString, forKey: key)
            return
        }

        guard let base64String = jsonString.base64Value else {
            throw PayloadError.convertionFailed
        }
        set(base64String, forKey: key)
    }

    private let isBase64Encoded: Bool
    private(set) var values = [PropertyKey: String]()

}

extension Payload {

    subscript(key: PropertyKey) -> PropertyKey? {
        return values[key]
    }

}

extension Payload {

    enum PayloadError: Error {
        case convertionFailed
    }

}
