import Foundation
import OSLog

public final class Tracker {
  public struct Configuration: Sendable {
    public enum RequestMethod: Sendable {
      case get
      case post
    }

    public let applicationId: String
    public let name: String
    public let baseURL: String
    public let requestMethod: RequestMethod
    public let payloadFlushFrequency: Int
    public let payloadPersistenceEnabled: Bool

    public init(applicationId: String,
                name: String = "",
                baseURL: String,
                requestMethod: RequestMethod = .post,
                payloadFlushFrequency: Int = 10,
                payloadPersistenceEnabled: Bool = true) {
      self.applicationId = applicationId
      self.name = name
      self.baseURL = baseURL
      self.requestMethod = requestMethod
      self.payloadFlushFrequency = payloadFlushFrequency
      self.payloadPersistenceEnabled = payloadPersistenceEnabled
    }
  }

  public var userId: String? {
    get { userIdValue }
    set { userIdValue = newValue }
  }

  private let applicationId: String
  private let emitter: Emitter
  private let isBase64Encoded: Bool
  private let logger: Logger = .init(subsystem: "SnowplowSwiftTracker", category: "Tracker")
  private let name: String
  private let session: Session
  private let trackerVersion = "2.0"

  @Locked private var userIdValue: String?

  // Logging
  public static var enabledLogCategories: [LogCategory] {
    get { logConfiguration.enabledCategories }
    set { logConfiguration.enabledCategories = newValue }
  }

  static func isLoggerEnabled(for category: LogCategory) -> Bool {
    logConfiguration.isEnabled(category)
  }

  private static let logConfiguration = LogConfiguration()

  private func trackerPayload() async -> Payload {
    let userId = self.userId
    let systemInfo = await MainActor.run {
      (
        platform: SystemInfo.platform,
        language: SystemInfo.language,
        resolution: SystemInfo.screenResolution,
        timezone: SystemInfo.timezone
      )
    }

    var content = [PropertyKey: String]()
    content[.trackerVersion] = trackerVersion
    content[.appId] = applicationId
    content[.namespace] = name
    content[.platform] = systemInfo.platform
    content[.language] = systemInfo.language
    content[.resolution] = systemInfo.resolution
    content[.viewPort] = systemInfo.resolution
    content[.timezone] = systemInfo.timezone
    content[.userId] = userId
    return Payload(content, base64Encoded: isBase64Encoded)
  }

  @MainActor
  public init(configuration: Configuration) {
    let requestMethod: Emitter.RequestMethod = switch configuration.requestMethod {
    case .get: .get
    case .post: .post
    }

    let emitter = Emitter(
      baseURL: configuration.baseURL,
      requestMethod: requestMethod,
      payloadFlushFrequency: configuration.payloadFlushFrequency,
      payloadPersistenceEnabled: configuration.payloadPersistenceEnabled
    )

    self.applicationId = configuration.applicationId
    self.emitter = emitter
    self.name = configuration.name
    self.isBase64Encoded = true
    self.session = Session()

    if Tracker.isLoggerEnabled(for: .tracker) {
      logger.info("❄️ Tracker initialized.")
    }
  }
}

// MARK: - Tracking

extension Tracker {
  func track(payload: Payload,
             contexts: [SelfDescribingJSON]? = nil,
             timestamp: TimeInterval? = nil) async {
    let eventId = UUID().uuidString.lowercased()
    let timestamp = Int((timestamp ?? Date().timeIntervalSince1970) * 1000)
    let sessionContext = await session.sessionContext(with: eventId)
    let platformContext = await platformContext()

    let allContexts: [SelfDescribingJSON] = (contexts ?? .init()) + [
      sessionContext,
      platformContext
    ]

    let allContextsDictionary = SelfDescribingJSON.dictionaryRepresentation(schema: .contexts, data: allContexts.map { $0.dictionaryRepresentation })

    let mergedPayloads = payload.merged(with: await trackerPayload())

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
    if Tracker.isLoggerEnabled(for: .tracker) {
      logger.debug("❄️ Tracking page view: \(uri).")
    }

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
    if Tracker.isLoggerEnabled(for: .tracker) {
      logger.debug("❄️ Tracking screen view: \(name).")
    }

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
    if Tracker.isLoggerEnabled(for: .tracker) {
      let values = [
        category.isEmpty ? "<empty category>" : category,
        action,
        property,
        label
      ]
        .compactMap({ $0 })
        .joined(separator: " – ")

      logger.debug("❄️ Tracking event: \(values).")
    }

    var content: SnowplowDictionary = [:]
    content[.event] = EventType.structured.rawValue
    content[.category] = category
    content[.action] = action
    content[.label] = label
    content[.property] = property

    if let value {
      content[.value] = String(describing: value)
    }

    let payload = Payload(content, base64Encoded: isBase64Encoded)
    await track(payload: payload, contexts: contexts, timestamp: timestamp)
  }

  func trackUnstructEvent(event: Payload,
                          contexts: [SelfDescribingJSON]? = nil,
                          timestamp: TimeInterval? = nil) async {
    let json = SelfDescribingJSON(schema: .unstructEvent, payload: event)

    guard let eventValue = json.base64EncodedRepresentation else {
      if Tracker.isLoggerEnabled(for: .tracker) {
        logger.error("❄️ Failed to encode the data.")
      }

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
  private func platformContext() async -> SelfDescribingJSON {
    let systemInfo = await MainActor.run {
      (
        osType: SystemInfo.osType,
        osVersion: SystemInfo.osVersion,
        deviceVendor: SystemInfo.deviceVendor,
        deviceModel: SystemInfo.deviceModel
      )
    }

    let data: SnowplowDictionary = [
      .platformOSType: systemInfo.osType,
      .platformOSVersion: systemInfo.osVersion,
      .platformDeviceManufacturer: systemInfo.deviceVendor,
      .platformDeviceModel: systemInfo.deviceModel
    ]
#if os(macOS)
    return SelfDescribingJSON(schema: .platformDesktop, dictionary: data)
#else
    return SelfDescribingJSON(schema: .platformMobile, dictionary: data)
#endif
  }
}
