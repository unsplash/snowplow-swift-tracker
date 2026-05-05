import Foundation
import OSLog

actor Emitter {
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
  private var isFlushing = false

  init(baseURL: String,
       requestMethod: RequestMethod = .post,
       payloadFlushFrequency: Int = 10,
       payloadPersistenceEnabled: Bool = true) {
    self.baseURL = baseURL
    self.requestFactory = .init(baseURL: baseURL)
    self.requestMethod = requestMethod
    self.payloadFlushFrequency = payloadFlushFrequency
    self.isPersistenceEnabled = payloadPersistenceEnabled

    let isEmitterLoggerEnabled = Tracker.isLoggerEnabled(for: .emitter)
    defer {
      if isEmitterLoggerEnabled {
        logger.info("❄️ Emitter initialized.")
      }
    }

    guard isPersistenceEnabled else {
      if isEmitterLoggerEnabled {
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
        if isEmitterLoggerEnabled {
          logger.info("❄️ Persistent storage initialized without a file.")
        }
        return
      }

      let encodedPayloads = try Data(contentsOf: url)
      payloads = try JSONCoding.decoder.decode([Payload].self, from: encodedPayloads)

      if isEmitterLoggerEnabled {
        let restoredPayloadCount = payloads.count
        logger.debug("❄️ Persistent file loaded with \(restoredPayloadCount) payloads.")
        logger.info("❄️ Persistent storage initialized with a file.")
      }
    } catch {
      if isEmitterLoggerEnabled {
        logger.error("❄️ Failed to initialize the persistent file: \(error)")
      }
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

      let encodedPayloads = try JSONCoding.encoder.encode(payloads)

      if Tracker.isLoggerEnabled(for: .emitter) {
        let payloadCount = payloads.count
        logger.debug("❄️ Saving \(payloadCount) payloads.")
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
  private enum FlushError: Error {
    case invalidResponse
    case unsuccessfulStatusCode(Int)
  }

  private func validateResponse(_ response: URLResponse) throws {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw FlushError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
      throw FlushError.unsuccessfulStatusCode(httpResponse.statusCode)
    }
  }

  private func needsFlush() -> Bool {
    switch requestMethod {
    case .get:
      return payloads.isEmpty == false
    case .post:
      return payloads.count >= payloadFlushFrequency
    }
  }

  private func flushIfNeeded() async {
    guard isFlushing == false  else { return }
    guard needsFlush() else { return }

    isFlushing = true
    defer { isFlushing = false }

    while needsFlush() {
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
        return
      }
    }
  }

  private func flush() async throws {
    switch requestMethod {
    case .get:
      if Tracker.isLoggerEnabled(for: .emitter) {
        logger.debug("❄️ Flushing payloads using the GET method.")
      }

      let payloadsToSend = payloads
      for payload in payloadsToSend {
        let request = try requestFactory.getRequest(for: payload)
        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        removePayloads([payload])
      }

    case .post:
      if Tracker.isLoggerEnabled(for: .emitter) {
        logger.debug("❄️ Flushing payloads using the POST method.")
      }

      let payloadsToSend = payloads
      guard payloadsToSend.isEmpty == false else { return }

      let request = try requestFactory.postRequest(for: payloadsToSend)

      let (_, response) = try await URLSession.shared.data(for: request)
      try validateResponse(response)
      removePayloads(payloadsToSend)
    }
  }
}

extension Emitter {
  enum RequestMethod: Sendable {
    case get
    case post
  }
}
