//
//  Payload.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-04-05.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation

struct Payload {

    private(set) var content = [String: String]()
    private let isBase64Encoded: Bool

    init(isBase64Encoded: Bool = true) {
        self.isBase64Encoded = isBase64Encoded
    }

    init(_ content: [PropertyKey: String], isBase64Encoded: Bool = true) {
        self.init(isBase64Encoded: isBase64Encoded)
        for (key, value) in content {
            self.content[key.rawValue] = value
        }
    }

    mutating func set(_ value: String?, forKey key: PropertyKey) {
        content[key.rawValue] = value
    }

    mutating func set(_ object: [String: Any], forKey key: PropertyKey) {
        do {
            let data = try JSONSerialization.data(withJSONObject: object, options: [])
            set(data, forKey: key)
        } catch {
            debugPrint(error)
        }
    }

    mutating func set(_ payload: Payload, forKey key: PropertyKey) {
        do {
            let data = try JSONEncoder().encode(payload.content)
            set(data, forKey: key)
        } catch {
            debugPrint(error)
        }
    }

    mutating func set(_ json: SelfDescribingJSON, forKey key: PropertyKey) {
        set(json.dictionaryRepresentation, forKey: key)
    }

    mutating private func set(_ data: Data, forKey key: PropertyKey) {
        let string = isBase64Encoded ? data.base64EncodedString(options: []) : String(data: data, encoding: .utf8)
        set(string, forKey: key)
    }

    mutating func add(values: [PropertyKey: String]) {
        for (key, value) in values {
            content[key.rawValue] = value
        }
    }

    mutating func merge(payload: Payload) {
        content.merge(payload.content, uniquingKeysWith: { (current, _) in current })
    }

    subscript(key: PropertyKey) -> String? {
        set { content[key.rawValue] = newValue }
        get { return content[key.rawValue] }
    }

}
