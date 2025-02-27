//
//  Payload.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-04-05.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation
import os

public struct Payload: Identifiable, Sendable {
  public let id: String
  public let content: SnowplowDictionary
  private let isBase64Encoded: Bool

  public init(_ content: SnowplowDictionary, base64Encoded: Bool = true) {
    self.id = UUID().uuidString
    self.isBase64Encoded = base64Encoded
    self.content = content
  }

  public init(_ content: SelfDescribingJSON, base64Encoded: Bool = true) {
    self.id = UUID().uuidString
    self.isBase64Encoded = base64Encoded
    self.content = [
      .schema: content.schema.rawValue,
      .data: content.data
    ]
  }

  public func merged(with payload: Payload) -> Payload {
    var newContent = content
    newContent.merge(payload.content, uniquingKeysWith: { (current, _) in current })
    return Payload(newContent, base64Encoded: isBase64Encoded)
  }
}

extension Payload: Equatable {
  public static func == (lhs: Payload, rhs: Payload) -> Bool {
    lhs.id == rhs.id
  }
}
