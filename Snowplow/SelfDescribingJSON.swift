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
    let data: Any?

    init(schema: SchemaDefinition, data: Payload) {
        self.schema = schema
        self.data = data.content
    }

    init(schema: SchemaDefinition, data: [Payload]) {
        self.schema = schema
        self.data = data.map({ $0.content })
    }

    init(schema: SchemaDefinition, data: SelfDescribingJSON) {
        self.schema = schema
        self.data = data.dictionaryRepresentation
    }

    init(schema: SchemaDefinition, data: [SelfDescribingJSON]) {
        self.schema = schema
        self.data = data.map({ $0.dictionaryRepresentation })
    }

    init(schema: SchemaDefinition, data: [PropertyKey: Any]) {
        self.schema = schema
        var dictionary = [String: Any]()
        for (key, value) in data {
            dictionary[key.rawValue] = value
        }
        self.data = dictionary
    }

    var dictionaryRepresentation: [String: Any] {
        guard let data = data else { return [:] }
        return [
            PropertyKey.schema.rawValue: schema.rawValue,
            PropertyKey.data.rawValue: data
        ]
    }

}
