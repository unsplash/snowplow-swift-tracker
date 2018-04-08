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

    mutating func set(_ value: String?, forKey key: String) {
        self.values[key] = value
    }

    mutating func set(_ object: [String: Any], forKey key: String) throws {
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
    private(set) var values = [String: String]()

}

extension Payload {

    subscript(key: String) -> String? {
        return values[key]
    }

}

extension Payload {

    enum PayloadError: Error {
        case convertionFailed
    }

}
