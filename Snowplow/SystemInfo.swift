//
//  SystemInfo.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-06-18.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

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
        #elseif os(iOS) || os(watchOS)
        return PlatformName.mobile.rawValue
        #else
        return PlatformName.computer.rawValue
        #endif
    }

    static var screenResolution: String {
        #if os(macOS)
        let size = NSScreen.main?.frame.size ?? .zero
        let scale = NSScreen.main?.backingScaleFactor ?? 1
        #else
        let size = UIScreen.main.bounds.size
        let scale = UIScreen.main.scale
        #endif

        let width = size.width * scale
        let height = size.height * scale
        return String(format: "%.0fx%.0f", width, height)
    }

    static let deviceVendor = "Apple Inc."

    static var deviceModel: String {
        #if os(macOS)
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0,  count: size)
        sysctlbyname("hw.model", &machine, &size, nil, 0)
        return String(cString: machine)
        #else
        return UIDevice.current.model
        #endif
    }

    static var osVersion: String {
        #if os(macOS)
        let osVersion = ProcessInfo().operatingSystemVersion
        return [osVersion.majorVersion, osVersion.minorVersion, osVersion.patchVersion].map({ "\($0)" }).joined(separator: ".")
        #else
        return UIDevice.current.systemVersion
        #endif
    }

    static var osType: String {
        #if os(tvOS)
        return "tvos"
        #elseif os(iOS) || os(watchOS)
        return "ios"
        #else
        return "mac"
        #endif
    }

    static var appId: String? {
        return Bundle.main.bundleIdentifier
    }

}
