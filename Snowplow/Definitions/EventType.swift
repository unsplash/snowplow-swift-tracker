//
//  EventType.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-06-08.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation

enum EventType: String {
  case pageView         = "pv"
  case structured       = "se"
  case unstructured     = "ue"
  case ecommerce        = "tr"
  case ecommerceItem    = "ti"
}
