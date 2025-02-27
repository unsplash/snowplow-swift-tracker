import Foundation
import os.log

public actor Emitter {
  public let payloadFlushFrequency: Int

  private let baseURL: String
  private let logger: Logger = .init(subsystem: "SnowplowSwiftTracker", category: "Emitter")
  private let payloadStorage: PayloadStorage
  private let requestFactory: EmitterRequestFactory
  private let requestMethod: RequestMethod

  public init(baseURL: String,
              requestMethod: RequestMethod = .post,
              payloadFlushFrequency: Int = 10,
              payloadPersistenceEnabled: Bool = true) {
    self.baseURL = baseURL
    self.requestFactory = .init(baseURL: baseURL)
    self.requestMethod = requestMethod
    self.payloadFlushFrequency = payloadFlushFrequency
    self.payloadStorage = PayloadStorage(persistenceEnabled: payloadPersistenceEnabled)
    logger.info("Emitter initialized.")
  }
  
  func input(_ payload: Payload) async {
    await payloadStorage.append(payload)
    await flushIfNeeded()
  }
}

// MARK: - Flush

extension Emitter {
  private func needsFlush() async -> Bool {
    let payloadCount = await payloadStorage.payloadCount
    return requestMethod == .get || payloadCount >= payloadFlushFrequency
  }
  
  private func flushIfNeeded() async {
    guard await needsFlush() else { return }
    
    do {
      logger.info("Flushing payloads.")
      try await flush()
      logger.info("Payloads flushed.")
    } catch {
      logger.error("Failed to flush payloads: \(error).")
    }
  }

  private func flush() async throws {
    switch requestMethod {
    case .get:
      logger.debug("Flushing payloads using the GET method.")
      let payloads = await payloadStorage.payloads
      try await withThrowingTaskGroup(of: Void.self) { group in
        for payload in payloads {
          group.addTask { [self] in
            let request = try requestFactory.getRequest(for: payload)
            _ = try await URLSession.shared.data(for: request)
            await payloadStorage.remove([payload])
          }
          try await group.next()
        }
      }

    case .post:
      logger.debug("Flushing payloads using the POST method.")
      let payloads = await payloadStorage.payloads
      let request = try requestFactory.postRequest(for: payloads)
      _ = try await URLSession.shared.data(for: request)
      await payloadStorage.remove(payloads)
    }
  }
}

public extension Emitter {
  enum RequestMethod: Sendable {
    case get
    case post
  }
}
