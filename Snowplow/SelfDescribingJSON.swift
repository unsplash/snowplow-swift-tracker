//
//  SelfDescribingJSON.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-04-07.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation

struct SelfDescribingJSON {

    let schema: SchemaDefinition
    let data: [PropertyKey: Any]

    var jsonObject: [PropertyKey: Any] {
        return [
            PropertyKey.schema: schema,
            PropertyKey.data: data
        ]
    }

}
