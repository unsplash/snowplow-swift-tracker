//
//  Constants.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-04-05.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation

struct Constants {
    static let schema = SchemaConstants()
}

struct SchemaConstants {
    let payloadDataSchema = "iglu:com.snowplowanalytics.snowplow/payload_data/jsonschema/1-0-0"
}
