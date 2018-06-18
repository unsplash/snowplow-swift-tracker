//
//  SystemInfo.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-06-18.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import UIKit
import Foundation

struct SystemInfo {

    static var timezone: String {
        return NSTimeZone.system.identifier
    }

    static var language: String? {
        return NSLocale.preferredLanguages.first
    }

    static var platform: String {
        #if os(tvOS)
        return PlatformName.television.rawValue
        #endif

        #if os(iOS) || os(watchOS)
        return PlatformName.mobile.rawValue
        #endif
    }

    static var screenResolution: String {
        let size = UIScreen.main.bounds.size
        let scale = UIScreen.main.scale
        let width = size.width * scale
        let height = size.height * scale
        return String(format: "%.0fx%.0f", width, height)
    }

    static let deviceVendor = "Apple Inc."

    static var deviceModel: String {
        return UIDevice.current.model
    }

    static var osVersion: String {
        return UIDevice.current.systemVersion
    }

    static var osType: String {
        #if os(tvOS)
        return "tvos"
        #endif

        #if os(iOS) || os(watchOS)
        return "ios"
        #endif
    }

    static var appId: String? {
        return Bundle.main.bundleIdentifier
    }

}
