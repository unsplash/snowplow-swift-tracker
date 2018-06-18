//
//  Tracker.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-04-07.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation

class Tracker {

    init(applicationId: String,
         platform: PlatformName,
         emitter: Emitter,
         name: String = "",
         isBase64Encoded: Bool = true) {
        self.applicationId = applicationId
        self.plaftorm = platform
        self.emitter = emitter
        self.name = name
        self.isBase64Encoded = isBase64Encoded
        self.session = Session()
    }

    // MARK: - Properties

    var userId = UUID().uuidString
    var plaftorm: PlatformName
    var screenResolution: String?
    var viewport: String?
    var colorDepth: String?
    var timezone: TimeZone?
    var language: String?
    var ipAddress: String?

    // MARK: - Private properties

    private let trackerVersion = "0.1"
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
        values[.platform] = plaftorm.rawValue
        values[.colorDepth] = colorDepth
        values[.language] = language
        values[.resolution] = screenResolution
        values[.viewPort] = viewport
        values[.timezone] = timezone?.identifier
        values[.userId] = userId
        values[.ipAddress] = ipAddress
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

        let contextKey: PropertyKey = isBase64Encoded ? .contextEncoded : .context
        payload.set(context, forKey: contextKey)

        let timestamp = Int((timestamp ?? Date().timeIntervalSince1970) * 1000)
        payload.set(String.init(describing: timestamp), forKey: .deviceTimestamp)

        emitter.input(payload)
    }

    func trackPageView(uri: String,
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

    func trackStructEvent(category: String,
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

    func trackUnstructEvent(event: Payload,
                            contexts: [SelfDescribingJSON]? = nil,
                            timestamp: TimeInterval? = nil) {
        let json = SelfDescribingJSON(schema: .unstructedEvent, data: event)
        var payload = Payload(isBase64Encoded: isBase64Encoded)
        payload.set(EventType.unstructured.rawValue, forKey: .event)
        let eventKey: PropertyKey = isBase64Encoded ? .unstructuredEncoded : .unstructured
        payload.set(json, forKey: eventKey)
        track(payload: payload, contexts: contexts, timestamp: timestamp)
    }

}

// MARK: - Context

extension Tracker {

    private func finalContexts(with contexts: [SelfDescribingJSON]?, eventId: String) -> [SelfDescribingJSON] {
        var allContexts = contexts ?? [SelfDescribingJSON]()

        let sessionContext = session.sessionContext(with: eventId)
        allContexts.append(sessionContext)

        return allContexts
    }

}
