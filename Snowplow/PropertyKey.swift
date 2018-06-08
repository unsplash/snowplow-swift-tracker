//
//  PropertyKey.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-04-05.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation

typealias PropertyKey = String

// Common
extension PropertyKey {
    static let schema              = "schema"
    static let data                = "data"
    static let trackerVersion      = "tv"
    static let context             = "co"
    static let contextEncoded      = "cx"
    static let unstructured        = "ue_pr"
    static let unstructuredEncoded = "ue_px"
}

// Application
extension PropertyKey {
    static let namespace = "tna"
    static let appId     = "aid"
    static let platform  = "p"
}

// Time
extension PropertyKey {
    static let deviceTimestamp = "dtm"
    static let sentTimestamp   = "stm"
    static let userTimestamp   = "ttm"
    static let timezone        = "tz"
}

// User
extension PropertyKey {
    static let networkId         = "tnuid"
    static let domainId          = "duid"
    static let userId            = "uid"
    static let sessionId         = "sid"
    static let sessionVisitCount = "vid"
    static let ipAddress         = "ip"
}

// Device
extension PropertyKey {
    static let resolution = "res"
    static let viewPort   = "vp"
    static let colorDepth = "cd"
    static let language   = "lang"
}

// Event
extension PropertyKey {
    static let event = "e"
    static let uuid  = "eid"
}

// Page view event
extension PropertyKey {
    static let url      = "url"
    static let title    = "page"
    static let referrer = "refr"
}

// Structured event
extension PropertyKey {
    static let category = "se_ca"
    static let action   = "se_ac"
    static let label    = "se_la"
    static let property = "se_pr"
    static let value    = "se_va"
}
