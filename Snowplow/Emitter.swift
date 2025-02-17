//
//  Emitter.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-04-05.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation
import os

public class Emitter {
  public var payloadFlushFrequency = 10
  
  private let baseURL: String
  private let requestMethod: RequestMethod
  private lazy var requestFactory: EmitterRequestFactory = .init(baseURL: baseURL)
  private let payloadStorage: PayloadStorage
  
  public init(baseURL: String,
              requestMethod: RequestMethod = .post,
              payloadPersistenceEnabled: Bool = true) {
    self.baseURL = baseURL
    self.requestMethod = requestMethod
    
    self.payloadStorage = PayloadStorage(payloadPersistenceEnabled: payloadPersistenceEnabled)
  }
  
  func input(_ payload: Payload) {
    Task {
      await payloadStorage.append(payload)
      await flushIfNeeded()
    }
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
      try await flush()
    } catch {
      os_log("%@", log: OSLog.default, type: OSLogType.error, error.localizedDescription)
    }
  }
  
  private func flush() async throws {
    switch requestMethod {
    case .get:
      let payloads = await payloadStorage.payloads
      await withTaskGroup(of: Void.self) { taskGroup in
        payloads.forEach { payload in
          taskGroup.addTask { [self] in
            do {
              let request = try requestFactory.getRequest(for: payload)
              _ = try await URLSession.shared.data(for: request)
              await payloadStorage.remove(payloads: [payload])
            } catch {
              os_log("%@", log: .default, type: .error, error.localizedDescription)
            }
          }
        }
      }
      
    case .post:
      let payloads = await payloadStorage.payloads
      let request = try requestFactory.postRequest(for: payloads)
      _ = try await URLSession.shared.data(for: request)
      
      await payloadStorage.remove(payloads: payloads)
    }
  }
  
}

public extension Emitter {
  
  enum RequestMethod {
    case get
    case post
  }
  
}
