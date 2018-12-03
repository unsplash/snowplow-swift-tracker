//
//  PropertyKey.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-04-05.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation

public enum PropertyKey: String {

    // Common
    case schema              = "schema"
    case data                = "data"
    case trackerVersion      = "tv"
    case context             = "co"
    case contextEncoded      = "cx"
    case unstructured        = "ue_pr"
    case unstructuredEncoded = "ue_px"

    // Application
    case namespace = "tna"
    case appId     = "aid"
    case platform  = "p"

    // Time
    case deviceTimestamp = "dtm"
    case sentTimestamp   = "stm"
    case userTimestamp   = "ttm"
    case timezone        = "tz"

    // User
    case networkId         = "tnuid"
    case domainId          = "duid"
    case userId            = "uid"
    case sessionId         = "sid"
    case sessionVisitCount = "vid"
    case ipAddress         = "ip"

    // Device
    case resolution = "res"
    case viewPort   = "vp"
    case colorDepth = "cd"
    case language   = "lang"

    // Event
    case event = "e"
    case uuid  = "eid"

    // Page view event
    case url      = "url"
    case title    = "page"
    case referrer = "refr"

    // Screen view event
    case name       = "name"
    case identifier = "id"

    // Structured event
    case category = "se_ca"
    case action   = "se_ac"
    case label    = "se_la"
    case property = "se_pr"
    case value    = "se_va"

    // Session context
    case sessionContextSessionId         = "sessionId"
    case sessionContextUserId            = "userId"
    case sessionContextPreviousSessionId = "previousSessionId"
    case sessionContextSessionIndex      = "sessionIndex"
    case sessionContextFirstEventId      = "firstEventId"
    case sessionContextStorageMechanism  = "storageMechanism"

    // Platform context
    case platformOSType             = "osType"
    case platformOSVersion          = "osVersion"
    case platformDeviceManufacturer = "deviceManufacturer"
    case platformDeviceModel        = "deviceModel"
}
