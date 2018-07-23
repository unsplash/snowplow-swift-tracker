//
//  SchemaDefinition.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-06-08.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation

public enum SchemaDefinition: String {
    case contexts        = "iglu:com.snowplowanalytics.snowplow/contexts/jsonschema/1-0-1"
    case platformMobile  = "iglu:com.snowplowanalytics.snowplow/mobile_context/jsonschema/1-0-1"
    case platformDesktop = "iglu:com.snowplowanalytics.snowplow/desktop_context/jsonschema/1-0-0"
    case payloadData     = "iglu:com.snowplowanalytics.snowplow/payload_data/jsonschema/1-0-0"
    case unstructedEvent = "iglu:com.snowplowanalytics.snowplow/unstruct_event/jsonschema/1-0-0"
    case session         = "iglu:com.snowplowanalytics.snowplow/client_session/jsonschema/1-0-1"
}
