//
//  URL+Extensions.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-06-11.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation

extension URL {

    enum AppFolder: String {
        case home               = ""
        case documents          = "Documents"
        case library            = "Library"
        case caches             = "Library/Caches"
        case applicationSupport = "Library/Application Support"
    }

    init(appFolder: AppFolder) {
        var path = NSHomeDirectory()
        path.append("/")
        path.append(appFolder.rawValue)
        self.init(fileURLWithPath: path, isDirectory: true)
    }

}
