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

    private(set) var content = [String: Any]()
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

    public init(_ content: SelfDescribingJSON, isBase64Encoded: Bool = true) {
        self.init(isBase64Encoded: isBase64Encoded)
        for (key, value) in content.dictionaryRepresentation {
            self.content[key] = value
        }
    }

    public mutating func set(_ value: String?, forKey key: PropertyKey) {
        content[key.rawValue] = value
    }

    public mutating func set(_ object: [String: Any], forKey key: PropertyKey) {
        content[key.rawValue] = object
    }

    public mutating func set(_ payload: Payload, forKey key: PropertyKey) {
        content[key.rawValue] = payload.content
    }

    public mutating func set(_ json: SelfDescribingJSON, forKey key: PropertyKey) {
        set(json.dictionaryRepresentation, forKey: key)
    }

    public mutating func add(values: [PropertyKey: String]) {
        for (key, value) in values {
            content[key.rawValue] = value
        }
    }

    public mutating func merge(payload: Payload) {
        content.merge(payload.content, uniquingKeysWith: { (current, _) in current })
    }

    public subscript(key: PropertyKey) -> Any? {
        set { content[key.rawValue] = newValue }
        get { return content[key.rawValue] }
    }

    public static func == (lhs: Payload, rhs: Payload) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

}

extension Payload: Codable {

    private enum CodingKeys: String, CodingKey {
        case content
        case isBase64Encoded
        case hashValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let contentData = try container.decode(Data.self, forKey: .content)
        guard let decodedContent = try JSONSerialization.jsonObject(with: contentData, options: []) as? [String: Any] else {
            throw DecodingError.dataCorruptedError(forKey: CodingKeys.content, in: container, debugDescription: "")
        }
        content = decodedContent
        isBase64Encoded = try container.decode(Bool.self, forKey: .isBase64Encoded)
        hashValue = try container.decode(Int.self, forKey: .hashValue)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let contentData = try JSONSerialization.data(withJSONObject: content, options: [])
        try container.encode(contentData, forKey: .content)
        try container.encode(isBase64Encoded, forKey: .isBase64Encoded)
        try container.encode(hashValue, forKey: .hashValue)
    }

}
