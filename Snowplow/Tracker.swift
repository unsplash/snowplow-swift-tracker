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
    var content = [PropertyKey: String]()
    content[.trackerVersion] = trackerVersion
    content[.appId] = applicationId
    content[.namespace] = name
    content[.platform] = SystemInfo.platform
    content[.language] = SystemInfo.language
    content[.resolution] = SystemInfo.screenResolution
    content[.viewPort] = SystemInfo.screenResolution
    content[.timezone] = SystemInfo.timezone
    content[.userId] = userId
    return Payload(content, base64Encoded: isBase64Encoded)
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
    let sessionContext = session.sessionContext(with: eventId)

    let allContexts: [SelfDescribingJSON] = (contexts ?? .init()) + [
      sessionContext,
      platformContext
    ]

    let allContextsDictionary = SelfDescribingJSON.dictionaryRepresentation(schema: .contexts, data: allContexts.map { $0.dictionaryRepresentation })

    let mergedPayloads = payload.merged(with: trackerPayload)
    
    var finalContent: SnowplowDictionary = mergedPayloads.content
    finalContent[.deviceTimestamp] = String(describing: timestamp)
    finalContent[.uuid] = eventId
    
    if isBase64Encoded, let contextValue = allContextsDictionary.base64EncodedRepresentation {
      finalContent[.contextEncoded] = contextValue
    } else {
      finalContent[.context] = allContextsDictionary
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
    var content: SnowplowDictionary = [:]
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
    var data: SnowplowDictionary = [.name: name]
    if let identifier = identifier {
      data[.identifier] = identifier
    }
    let json = SelfDescribingJSON(schema: .screenView, dictionary: data)
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
    var content: SnowplowDictionary = [:]
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
    let json = SelfDescribingJSON(schema: .unstructedEvent, payload: event)
    guard let eventValue = json.base64EncodedRepresentation else {
      logger.error("Failed to encode the data.")
      return
    }

    let eventKey: PropertyKey = isBase64Encoded ? .unstructuredEncoded : .unstructured

    var content: SnowplowDictionary = [:]
    content[.event] = EventType.unstructured.rawValue
    content[eventKey] = eventValue
    let payload = Payload(content, base64Encoded: isBase64Encoded)
    await track(payload: payload, contexts: contexts, timestamp: timestamp)
  }
}

// MARK: - Context

extension Tracker {
  private var platformContext: SelfDescribingJSON {
    let data: SnowplowDictionary = [
      .platformOSType: SystemInfo.osType,
      .platformOSVersion: SystemInfo.osVersion,
      .platformDeviceManufacturer: SystemInfo.deviceVendor,
      .platformDeviceModel: SystemInfo.deviceModel
    ]
#if os(macOS)
    return SelfDescribingJSON(schema: .platformDesktop, dictionary: data)
#else
    return SelfDescribingJSON(schema: .platformMobile, dictionary: data)
#endif
  }
}
