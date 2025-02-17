//
//  Tracker.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-04-07.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation

public class Tracker {

  public init(applicationId: String,
              emitter: Emitter,
              name: String = "") {
    self.applicationId = applicationId
    self.emitter = emitter
    self.name = name
    self.isBase64Encoded = true
    self.session = Session()
  }

  // MARK: - Properties

  public var userId: String?

  // MARK: - Private properties

  private let trackerVersion = "1.0"
  private let applicationId: String
  private let name: String
  private let isBase64Encoded: Bool
  private let emitter: Emitter
  private let session: Session

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
    return Payload(values, isBase64Encoded: isBase64Encoded)
  }

}

// MARK: - Tracking

extension Tracker {

  func track(payload: Payload,
             contexts: [SelfDescribingJSON]? = nil,
             timestamp: TimeInterval? = nil) {
    var payload = payload
    payload.merge(payload: trackerPayload)

    let eventId = UUID().uuidString.lowercased()
    payload.set(eventId, forKey: .uuid)

    let allContexts = finalContexts(with: contexts, eventId: eventId)
    let data = allContexts
    let context = SelfDescribingJSON(schema: .contexts, data: data)

    if isBase64Encoded, let contextValue = context.base64EncodedRepresentation {
      payload.set(contextValue, forKey: .contextEncoded)
    } else {
      payload.set(context, forKey: .context)
    }

    let timestamp = Int((timestamp ?? Date().timeIntervalSince1970) * 1000)
    payload.set(String.init(describing: timestamp), forKey: .deviceTimestamp)

    emitter.input(payload)
  }

  public func trackPageView(uri: String,
                            title: String? = nil,
                            referrer: String? = nil,
                            contexts: [SelfDescribingJSON]? = nil,
                            timestamp: TimeInterval? = nil) {
    var payload = Payload(isBase64Encoded: isBase64Encoded)
    payload.set(EventType.pageView.rawValue, forKey: .event)
    payload.set(uri, forKey: .url)
    payload.set(title, forKey: .title)
    payload.set(referrer, forKey: .referrer)
    track(payload: payload, contexts: contexts, timestamp: timestamp)
  }

  public func trackScreenView(name: String,
                              identifier: String? = nil) {
    var data: [PropertyKey: String] = [.name: name]
    if let identifier = identifier {
      data[.identifier] = identifier
    }
    let json = SelfDescribingJSON(schema: .screenView, data: data)
    let payload = Payload(json, base64Encoded: isBase64Encoded)
    trackUnstructEvent(event: payload)
  }

  public func trackStructEvent(category: String,
                               action: String,
                               label: String? = nil,
                               property: String? = nil,
                               value: Double? = nil,
                               contexts: [SelfDescribingJSON]? = nil,
                               timestamp: TimeInterval? = nil) {
    var payload = Payload(isBase64Encoded: isBase64Encoded)
    payload.set(EventType.structured.rawValue, forKey: .event)
    payload.set(category, forKey: .category)
    payload.set(action, forKey: .action)
    if let label = label {
      payload.set(label, forKey: .label)
    }
    if let property = property {
      payload.set(property, forKey: .property)
    }
    if let value = value {
      payload.set(String(describing: value), forKey: .value)
    }
    track(payload: payload, contexts: contexts, timestamp: timestamp)
  }

  public func trackUnstructEvent(event: Payload,
                                 contexts: [SelfDescribingJSON]? = nil,
                                 timestamp: TimeInterval? = nil) {
    let json = SelfDescribingJSON(schema: .unstructedEvent, data: event)
    guard let eventValue = json.base64EncodedRepresentation else { return }

    var payload = Payload(isBase64Encoded: isBase64Encoded)
    payload.set(EventType.unstructured.rawValue, forKey: .event)

    let eventKey: PropertyKey = isBase64Encoded ? .unstructuredEncoded : .unstructured
    payload.set(eventValue, forKey: eventKey)

    track(payload: payload, contexts: contexts, timestamp: timestamp)
  }

}

// MARK: - Context

extension Tracker {

  private func finalContexts(with contexts: [SelfDescribingJSON]?, eventId: String) -> [SelfDescribingJSON] {
    var allContexts = contexts ?? [SelfDescribingJSON]()

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
