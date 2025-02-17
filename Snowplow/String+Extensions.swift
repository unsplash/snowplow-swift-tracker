//
//  String+Extensions.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-04-05.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation

// MARK: - Base 64 decoding / encoding

extension String {
  
  init?(base64Value: String) {
    guard let data = Data(base64Encoded: base64Value, options: Data.Base64DecodingOptions(rawValue: 0)) else {
      return nil
    }
    self.init(data: data, encoding: .utf8)
  }
  
  var base64Value: String? {
    guard let data = self.data(using: .utf8) else {
      return nil
    }
    
    return data.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
  }
  
}
