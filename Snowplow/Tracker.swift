//
//  Tracker.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-04-07.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation
import os.log

@MainActor
public class Tracker {
  public var userId: String?

  private let applicationId: String
  private let emitter: Emitter
  private let isBase64Encoded: Bool
  private let logger: Logger = .init(subsystem: "SnowplowSwiftTracker", category: "Tracker")
  private let name: String
  private let session: Session
  private let trackerVersion = "1.0"

  private var trackerPayload: Payload {
    var values = [PropertyKey: String]()
    values[.trackerVersion] = trackerVersion
    values[.appId] = applicationId
    values[.namespace] = name
    values[.platform] = SystemInfo.platform
    values[.language] = SystemInfo.language
    values[.resolution] = SystemInfo.screenResolution
    values[.viewPort] = SystemInfo.screenResolution
    values[.timezone] = SystemInfo.timezone
    values[.userId] = userId
    return Payload(values, base64Encoded: isBase64Encoded)
  }

  public init(applicationId: String,
              emitter: Emitter,
              name: String = "") {
    self.applicationId = applicationId
    self.emitter = emitter
    self.name = name
    self.isBase64Encoded = true
    self.session = Session()

    logger.info("Tracker initialized.")
  }
}

// MARK: - Tracking

extension Tracker {
  func track(payload: Payload,
             contexts: [SelfDescribingJSON]? = nil,
             timestamp: TimeInterval? = nil) async {
    let eventId = UUID().uuidString.lowercased()
    let timestamp = Int((timestamp ?? Date().timeIntervalSince1970) * 1000)
    let allContexts = finalContexts(with: contexts, eventId: eventId)
    let context = SelfDescribingJSON(schema: .contexts, data: allContexts)
    let mergedPayloads = payload.merged(with: trackerPayload)

    var finalContent: PayloadContent = mergedPayloads.content
    finalContent[.deviceTimestamp] = String(describing: timestamp)
    finalContent[.uuid] = eventId

    if isBase64Encoded, let contextValue = context.base64EncodedRepresentation {
      finalContent[.contextEncoded] = contextValue
    } else {
      finalContent[.context] = context
    }

    let finalPayload = Payload(finalContent, base64Encoded: isBase64Encoded)
    await emitter.input(finalPayload)
  }

  public func trackPageView(uri: String,
                            title: String? = nil,
                            referrer: String? = nil,
                            contexts: [SelfDescribingJSON]? = nil,
                            timestamp: TimeInterval? = nil) async {
    logger.debug("Tracking page view: \(uri).")
    var content: PayloadContent = [:]
    content[.event] = EventType.pageView.rawValue
    content[.url] = uri
    content[.title] = title
    content[.referrer] = referrer
    let payload = Payload(content, base64Encoded: isBase64Encoded)
    await track(payload: payload, contexts: contexts, timestamp: timestamp)
  }

  public func trackScreenView(name: String,
                              identifier: String? = nil) async {
    logger.debug("Tracking screen view: \(name).")
    var data: [PropertyKey: String] = [.name: name]
    if let identifier = identifier {
      data[.identifier] = identifier
    }
    let json = SelfDescribingJSON(schema: .screenView, data: data)
    let payload = Payload(json, base64Encoded: isBase64Encoded)
    await trackUnstructEvent(event: payload)
  }

  public func trackStructEvent(category: String,
                               action: String,
                               label: String? = nil,
                               property: String? = nil,
                               value: Double? = nil,
                               contexts: [SelfDescribingJSON]? = nil,
                               timestamp: TimeInterval? = nil) async {
    logger.debug("Tracking event: \(category) - \(action).")
    var content: PayloadContent = [:]
    content[.event] = EventType.structured.rawValue
    content[.category] = category
    content[.action] = action
    content[.label] = label
    content[.property] = property
    content[.value] = String(describing: value)
    let payload = Payload(content, base64Encoded: isBase64Encoded)
    await track(payload: payload, contexts: contexts, timestamp: timestamp)
  }

  public func trackUnstructEvent(event: Payload,
                                 contexts: [SelfDescribingJSON]? = nil,
                                 timestamp: TimeInterval? = nil) async {
    let json = SelfDescribingJSON(schema: .unstructedEvent, data: event)
    guard let eventValue = json.base64EncodedRepresentation else { return }

    let eventKey: PropertyKey = isBase64Encoded ? .unstructuredEncoded : .unstructured

    var content: PayloadContent = [:]
    content[.event] = EventType.unstructured.rawValue
    content[eventKey] = eventValue
    let payload = Payload(content, base64Encoded: isBase64Encoded)
    await track(payload: payload, contexts: contexts, timestamp: timestamp)
  }
}

// MARK: - Context

extension Tracker {
  private func finalContexts(with contexts: [SelfDescribingJSON]?, eventId: String) -> [SelfDescribingJSON] {
    var allContexts: [SelfDescribingJSON] = contexts ?? .init()

    let sessionContext = session.sessionContext(with: eventId)
    allContexts.append(sessionContext)
    allContexts.append(platformContext)

    return allContexts
  }

  private var platformContext: SelfDescribingJSON {
    let data: [PropertyKey: String] = [
      .platformOSType: SystemInfo.osType,
      .platformOSVersion: SystemInfo.osVersion,
      .platformDeviceManufacturer: SystemInfo.deviceVendor,
      .platformDeviceModel: SystemInfo.deviceModel
    ]
#if os(macOS)
    return SelfDescribingJSON(schema: .platformDesktop, data: data)
#else
    return SelfDescribingJSON(schema: .platformMobile, data: data)
#endif
  }
}
