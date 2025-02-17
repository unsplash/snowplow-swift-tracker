//
//  PayloadStorage.swift
//  Snowplow
//
//  Created by Olivier Collet on 2023-07-17.
//  Copyright © 2023 Unsplash. All rights reserved.
//

import Foundation
import OSLog

actor PayloadStorage {
  var payloadCount: Int { payloads.count }
  
  private var persistenceFileURL: URL?
  private let isPayloadPersistenceEnabled: Bool
  private var cacheFilename = "SnowplowEmitterPayloads.data"
  private(set) var payloads: [Payload] = []
  
  init(payloadPersistenceEnabled: Bool = true) {
    isPayloadPersistenceEnabled = payloadPersistenceEnabled
    guard payloadPersistenceEnabled else { return }
    
    do {
      let bundleId: String = Bundle.main.bundleIdentifier ?? ""
      var url = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      url.appendPathComponent("Snowplow/\(bundleId)/\(cacheFilename)")
      persistenceFileURL = url
      
      guard FileManager().fileExists(atPath: url.path) else { return }
      
      let encodedPayloads = try Data(contentsOf: url)
      payloads = try JSONDecoder().decode([Payload].self, from: encodedPayloads)
    } catch {
      os_log("%@", log: OSLog.default, type: OSLogType.error, error.localizedDescription)
    }
  }
  
  func save() {
    guard isPayloadPersistenceEnabled, let persistenceFileURL else { return }
    
    do {
      let folderURL = persistenceFileURL.deletingLastPathComponent()
      if FileManager.default.fileExists(atPath: folderURL.path) == false {
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
      }
      
      let encodedPayloads = try JSONEncoder().encode(payloads)
      try encodedPayloads.write(to: persistenceFileURL, options: .atomic)
    } catch {
      os_log("%@", log: OSLog.default, type: OSLogType.error, error.localizedDescription)
    }
  }
  
  func append(_ payload: Payload) {
    payloads.append(payload)
    save()
  }
  
  func remove(payloads: [Payload]) {
    payloads.forEach { payload in
      guard let index = self.payloads.firstIndex(of: payload) else { return }
      self.payloads.remove(at: index)
    }
    save()
  }
}
