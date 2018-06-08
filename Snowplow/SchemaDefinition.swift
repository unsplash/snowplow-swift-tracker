//
//  SchemaDefinition.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-06-08.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation

typealias SchemaDefinition = String

extension SchemaDefinition {
    static let payloadData     = "iglu:com.snowplowanalytics.snowplow/payload_data/jsonschema/1-0-0"
    static let unstructedEvent = "iglu:com.snowplowanalytics.snowplow/unstruct_event/jsonschema/1-0-0"
}
