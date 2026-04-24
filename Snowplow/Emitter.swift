import Foundation
import OSLog

public actor Emitter {
  let payloadFlushFrequency: Int

  var storedPayloadCount: Int { payloads.count }

  private let baseURL: String
  private let logger: Logger = .init(subsystem: "SnowplowSwiftTracker", category: "Emitter")
  private let requestFactory: EmitterRequestFactory
  private let requestMethod: RequestMethod

  private let cacheFilename = "SnowplowEmitterPayloads.data"
  private let isPersistenceEnabled: Bool
  private var persistenceFileURL: URL?
  private var payloads: [Payload] = []

  public init(baseURL: String,
              requestMethod: RequestMethod = .post,
              payloadFlushFrequency: Int = 10,
              payloadPersistenceEnabled: Bool = true) async {
    self.baseURL = baseURL
    self.requestFactory = .init(baseURL: baseURL)
    self.requestMethod = requestMethod
    self.payloadFlushFrequency = payloadFlushFrequency
    self.isPersistenceEnabled = payloadPersistenceEnabled

    initializePersistentStorage()

    if Tracker.isLoggerEnabled(for: .emitter) {
      logger.info("❄️ Emitter initialized.")
    }
  }

  func input(_ payload: Payload) async {
    appendPayload(payload)
    await flushIfNeeded()
  }

  func removeAllStoredPayloads() {
    if Tracker.isLoggerEnabled(for: .emitter) {
      logger.debug("❄️ Removing \(self.storedPayloadCount) payloads.")
    }

    payloads.removeAll()
    save()
  }
}

// MARK: - Storage

extension Emitter {
  private func initializePersistentStorage() {
    guard isPersistenceEnabled else {
      if Tracker.isLoggerEnabled(for: .emitter) {
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
        if Tracker.isLoggerEnabled(for: .emitter) {
          logger.info("❄️ Persistent storage initialized without a file.")
        }
        return
      }

      let encodedPayloads = try Data(contentsOf: url)
      guard let storedPayloads = try JSONSerialization.jsonObject(with: encodedPayloads) as? [[String: Sendable]] else {
        throw PayloadStorageError.cannotDecodeStoredData
      }

      payloads = storedPayloads.compactMap { Payload(dictionary: $0) }

      if Tracker.isLoggerEnabled(for: .emitter) {
        logger.debug("❄️ Persistent file loaded with \(self.payloads.count) payloads.")
        logger.info("❄️ Persistent storage initialized with a file.")
      }
    } catch {
      if Tracker.isLoggerEnabled(for: .emitter) {
        logger.error("❄️ Failed to initialize the persistent file: \(error)")
      }
    }
  }

  private func save() {
    guard isPersistenceEnabled else {
      if Tracker.isLoggerEnabled(for: .emitter) {
        logger.debug("❄️ Save canceled: persistence is disabled.")
      }
      return
    }

    guard let persistenceFileURL else {
      if Tracker.isLoggerEnabled(for: .emitter) {
        logger.error("❄️ Failed to save payloads: no persistent file URL.")
      }
      return
    }

    do {
      let folderURL = persistenceFileURL.deletingLastPathComponent()
      if FileManager.default.fileExists(atPath: folderURL.path) == false {
        if Tracker.isLoggerEnabled(for: .emitter) {
          logger.debug("❄️ Persistent file does not exist, creating it.")
        }

        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

        if Tracker.isLoggerEnabled(for: .emitter) {
          logger.debug("❄️ Persistent file created.")
        }
      }

      let payloadsToEncode = payloads.compactMap { $0.dictionaryRepresentation }
      let encodedPayloads = try JSONSerialization.data(withJSONObject: payloadsToEncode)

      if Tracker.isLoggerEnabled(for: .emitter) {
        logger.debug("❄️ Saving \(payloadsToEncode.count) payloads.")
      }

      try encodedPayloads.write(to: persistenceFileURL, options: .atomic)

      if Tracker.isLoggerEnabled(for: .emitter) {
        logger.info("❄️ Payloads saved.")
      }
    } catch {
      if Tracker.isLoggerEnabled(for: .emitter) {
        logger.error("❄️ Failed to save to the persistent file: \(error)")
      }
    }
  }

  private func appendPayload(_ payload: Payload) {
    if Tracker.isLoggerEnabled(for: .emitter) {
      logger.debug("❄️ Adding a payload.")
    }

    payloads.append(payload)
    save()
  }

  private func removePayloads(_ payloadsToRemove: [Payload]) {
    if Tracker.isLoggerEnabled(for: .emitter) {
      logger.debug("❄️ Removing \(payloadsToRemove.count) payloads.")
    }

    payloadsToRemove.forEach { payload in
      guard let index = payloads.firstIndex(of: payload) else { return }
      payloads.remove(at: index)
    }

    save()
  }
}

// MARK: - Flush

extension Emitter {
  private func needsFlush() -> Bool {
    requestMethod == .get || payloads.count >= payloadFlushFrequency
  }

  private func flushIfNeeded() async {
    guard needsFlush() else { return }

    do {
      if Tracker.isLoggerEnabled(for: .emitter) {
        logger.info("❄️ Flushing payloads.")
      }

      try await flush()

      if Tracker.isLoggerEnabled(for: .emitter) {
        logger.info("❄️ Payloads flushed.")
      }
    } catch {
      if Tracker.isLoggerEnabled(for: .emitter) {
        logger.error("❄️ Failed to flush payloads: \(error).")
      }
    }
  }

  private func flush() async throws {
    switch requestMethod {
    case .get:
      if Tracker.isLoggerEnabled(for: .emitter) {
        logger.debug("❄️ Flushing payloads using the GET method.")
      }

      for payload in payloads {
        let request = try requestFactory.getRequest(for: payload)
        _ = try await URLSession.shared.data(for: request)
        removePayloads([payload])
      }

    case .post:
      if Tracker.isLoggerEnabled(for: .emitter) {
        logger.debug("❄️ Flushing payloads using the POST method.")
      }

      let request = try requestFactory.postRequest(for: payloads)

      _ = try await URLSession.shared.data(for: request)
      removePayloads(payloads)
    }
  }
}

public extension Emitter {
  enum RequestMethod: Sendable {
    case get
    case post
  }
}

public enum PayloadStorageError: Error {
  case cannotDecodeStoredData
}
