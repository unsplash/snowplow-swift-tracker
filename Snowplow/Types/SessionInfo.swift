//
//  SessionInfo.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-06-11.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation
import os

public struct SessionInfo: Codable {
  
  var userId: String
  var currentId: String
  var previousId: String?
  var index: Int
  var storage = "SQLITE"
  
  init(userId: String, currentId: String, previousId: String?, index: Int) {
    self.userId = userId
    self.currentId = currentId
    self.previousId = previousId
    self.index = index
  }
  
  init?(from url: URL) {
    guard let sessionData = try? Data(contentsOf: url),
          let sessionInfo = try? JSONDecoder().decode(SessionInfo.self, from: sessionData) else { return nil }
    
    userId = sessionInfo.userId
    currentId = sessionInfo.currentId
    previousId = sessionInfo.previousId
    index = sessionInfo.index
  }
  
  func write(to url: URL) {
    do {
      let folderURL = url.deletingLastPathComponent()
      if FileManager.default.fileExists(atPath: folderURL.path) == false {
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
      }
      
      let sessionData = try JSONEncoder().encode(self)
      try sessionData.write(to: url, options: .atomic)
    } catch {
      os_log("%@", log: OSLog.default, type: OSLogType.error, error.localizedDescription)
    }
  }
  
  mutating func update() {
    previousId = currentId
    currentId = UUID().uuidString.lowercased()
    index += 1
  }
  
}
