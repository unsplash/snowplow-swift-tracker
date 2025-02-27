//
//  Dictionary+Extensions.swift
//  Snowplow
//
//  Created by Olivier Collet on 2025-02-27.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation

extension [String: Sendable] {
  var base64EncodedRepresentation: String? {
    guard let data = try? JSONSerialization.data(withJSONObject: self) else {
      return nil
    }
    return data.base64EncodedString()
  }
}
