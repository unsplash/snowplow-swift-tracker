//
//  PayloadStorage.swift
//  Snowplow
//
//  Created by Olivier Collet on 2023-07-17.
//  Copyright © 2023 Unsplash. All rights reserved.
//

import Foundation
import os.log

actor PayloadStorage {
  var payloadCount: Int { payloads.count }
  private(set) var payloads: [Payload] = []
  
  private let cacheFilename = "SnowplowEmitterPayloads.data"
  private let isPersistenceEnabled: Bool
  private let logger: Logger = .init(subsystem: "SnowplowSwiftTracker", category: "PayloadStorage")
  private var persistenceFileURL: URL?
  
  init(persistenceEnabled: Bool = true) {
    isPersistenceEnabled = persistenceEnabled
    guard persistenceEnabled else {
      logger.info("Persistent storage initialized with persistent disabled.")
      return
    }

    do {
      let bundleId: String = Bundle.main.bundleIdentifier ?? ""
      var url = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      url.appendPathComponent("Snowplow/\(bundleId)/\(cacheFilename)")
      persistenceFileURL = url
      
      guard FileManager().fileExists(atPath: url.path) else {
        logger.info("Persistent storage initialized without a file.")
        return
      }

      let encodedPayloads = try Data(contentsOf: url)
      guard let storedPayloads = try JSONSerialization.jsonObject(with: encodedPayloads) as? [Payload] else {
        throw PayloadStorageError.cannotDecodeStoredData
      }
      payloads = storedPayloads
      logger.debug("Persistent file loaded with \(storedPayloads.count) payloads.")
      logger.info("Persistent storage initialized with a file.")
    } catch {
      logger.error("Failed to initialize the persistent file: \(error)")
    }
  }
  
  func save() {
    guard isPersistenceEnabled else {
      logger.debug("Save canceled: persistence is disabled.")
      return
    }

    guard let persistenceFileURL else {
      logger.error("Failed to save payloads: no persistent file URL.")
      return
    }

    do {
      let folderURL = persistenceFileURL.deletingLastPathComponent()
      if FileManager.default.fileExists(atPath: folderURL.path) == false {
        logger.debug("Persistent file does not exist, creating it.")
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        logger.debug("Persistent file created.")
      }
      
      let encodedPayloads = try JSONSerialization.data(withJSONObject: payloads)
      logger.debug("Saving \(encodedPayloads.count) payloads.")
      try encodedPayloads.write(to: persistenceFileURL, options: .atomic)
      logger.info("Payloads saved.")
    } catch {
      logger.log(level: .error, "Failed to save to the persistent file: \(error)")
    }
  }
  
  func append(_ payload: Payload) {
    logger.debug("Adding a payload.")
    payloads.append(payload)
    save()
  }
  
  func remove(_ payloadsToRemove: [Payload]) {
    logger.debug("Removing \(payloadsToRemove.count) payloads.")
    payloadsToRemove.forEach { payload in
      guard let index = payloads.firstIndex(of: payload) else { return }
      payloads.remove(at: index)
    }
    save()
  }
}

public enum PayloadStorageError: Error {
  case cannotDecodeStoredData
}
