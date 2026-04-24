import Foundation
import OSLog

actor PayloadStorage {
  var payloadCount: Int { payloads.count }
  private(set) var payloads: [Payload] = []
  
  private let cacheFilename = "SnowplowEmitterPayloads.data"
  private let isPersistenceEnabled: Bool
  private let logger: Logger = .init(subsystem: "SnowplowSwiftTracker", category: "PayloadStorage")
  private var persistenceFileURL: URL?

  init(persistenceEnabled: Bool = true) async {
    isPersistenceEnabled = persistenceEnabled

    guard persistenceEnabled else {
      if Tracker.isLoggerEnabled(for: .storage) {
        logger.info("❄️ Persistent storage initialized with persistent disabled.")
      }
      return
    }

    do {
      let bundleId: String = Bundle.main.bundleIdentifier ?? ""
      var url = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      url.appendPathComponent("Snowplow/\(bundleId)/\(cacheFilename)")
      persistenceFileURL = url
      
      guard FileManager().fileExists(atPath: url.path) else {
        if Tracker.isLoggerEnabled(for: .storage) {
          logger.info("❄️ Persistent storage initialized without a file.")
        }
        return
      }

      let encodedPayloads = try Data(contentsOf: url)
      guard let storedPayloads = try JSONSerialization.jsonObject(with: encodedPayloads) as? [[String: Sendable]] else {
        throw PayloadStorageError.cannotDecodeStoredData
      }

      let payloads = storedPayloads.compactMap { Payload(dictionary: $0) }
      self.payloads = payloads

      if Tracker.isLoggerEnabled(for: .storage) {
        logger.debug("❄️ Persistent file loaded with \(payloads.count) payloads.")
        logger.info("❄️ Persistent storage initialized with a file.")
      }
    } catch {
      if Tracker.isLoggerEnabled(for: .storage) {
        logger.error("❄️ Failed to initialize the persistent file: \(error)")
      }
    }
  }
  
  func save() async {
    guard isPersistenceEnabled else {
      if Tracker.isLoggerEnabled(for: .storage) {
        logger.debug("❄️ Save canceled: persistence is disabled.")
      }
      return
    }

    guard let persistenceFileURL else {
      if Tracker.isLoggerEnabled(for: .storage) {
        logger.error("❄️ Failed to save payloads: no persistent file URL.")
      }
      return
    }

    do {
      let folderURL = persistenceFileURL.deletingLastPathComponent()
      if FileManager.default.fileExists(atPath: folderURL.path) == false {
        if Tracker.isLoggerEnabled(for: .storage) {
          logger.debug("❄️ Persistent file does not exist, creating it.")
        }

        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

        if Tracker.isLoggerEnabled(for: .storage) {
          logger.debug("❄️ Persistent file created.")
        }
      }

      let payloadsToEncode = payloads.compactMap { $0.dictionaryRepresentation }
      let encodedPayloads = try JSONSerialization.data(withJSONObject: payloadsToEncode)

      if Tracker.isLoggerEnabled(for: .storage) {
        logger.debug("❄️ Saving \(payloadsToEncode.count) payloads.")
      }

      try encodedPayloads.write(to: persistenceFileURL, options: .atomic)

      if Tracker.isLoggerEnabled(for: .storage) {
        logger.info("❄️ Payloads saved.")
      }
    } catch {
      if Tracker.isLoggerEnabled(for: .storage) {
        logger.error("❄️ Failed to save to the persistent file: \(error)")
      }
    }
  }
  
  func append(_ payload: Payload) async {
    if Tracker.isLoggerEnabled(for: .storage) {
      logger.debug("❄️ Adding a payload.")
    }

    payloads.append(payload)
    await save()
  }
  
  func remove(_ payloadsToRemove: [Payload]) async {
    if Tracker.isLoggerEnabled(for: .storage) {
      logger.debug("❄️ Removing \(payloadsToRemove.count) payloads.")
    }

    payloadsToRemove.forEach { payload in
      guard let index = payloads.firstIndex(of: payload) else { return }
      payloads.remove(at: index)
    }

    await save()
  }

  func removeAll() async {
    if Tracker.isLoggerEnabled(for: .storage) {
      logger.debug("❄️ Removing \(self.payloadCount) payloads.")
    }

    payloads.removeAll()
    await save()
  }
}

public enum PayloadStorageError: Error {
  case cannotDecodeStoredData
}
