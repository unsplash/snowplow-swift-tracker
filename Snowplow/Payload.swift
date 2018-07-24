//
//  Payload.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-04-05.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation
import os

public struct Payload: Hashable {

    private(set) var content = [String: String]()
    private let isBase64Encoded: Bool
    public var hashValue: Int = UUID().uuidString.hashValue

    public init(isBase64Encoded: Bool = true) {
        self.isBase64Encoded = isBase64Encoded
    }

    public init(_ content: [PropertyKey: String], isBase64Encoded: Bool = true) {
        self.init(isBase64Encoded: isBase64Encoded)
        for (key, value) in content {
            self.content[key.rawValue] = value
        }
    }

    public mutating func set(_ value: String?, forKey key: PropertyKey) {
        content[key.rawValue] = value
    }

    public mutating func set(_ object: [String: Any], forKey key: PropertyKey) {
        do {
            let data = try JSONSerialization.data(withJSONObject: object, options: [])
            set(data, forKey: key)
        } catch {
            os_log("%@", log: OSLog.default, type: OSLogType.error, error.localizedDescription)
        }
    }

    public mutating func set(_ payload: Payload, forKey key: PropertyKey) {
        do {
            let data = try JSONEncoder().encode(payload.content)
            set(data, forKey: key)
        } catch {
            os_log("%@", log: OSLog.default, type: OSLogType.error, error.localizedDescription)
        }
    }

    public mutating func set(_ json: SelfDescribingJSON, forKey key: PropertyKey) {
        set(json.dictionaryRepresentation, forKey: key)
    }

    private mutating func set(_ data: Data, forKey key: PropertyKey) {
        let string = isBase64Encoded ? data.base64EncodedString(options: []) : String(data: data, encoding: .utf8)
        set(string, forKey: key)
    }

    public mutating func add(values: [PropertyKey: String]) {
        for (key, value) in values {
            content[key.rawValue] = value
        }
    }

    public mutating func merge(payload: Payload) {
        content.merge(payload.content, uniquingKeysWith: { (current, _) in current })
    }

    public subscript(key: PropertyKey) -> String? {
        set { content[key.rawValue] = newValue }
        get { return content[key.rawValue] }
    }

}
