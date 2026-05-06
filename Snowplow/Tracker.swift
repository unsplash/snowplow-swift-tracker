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
    public let encodeBase64: Bool
    public let sessionForegroundTimeout: TimeInterval
    public let sessionBackgroundTimeout: TimeInterval
    public let sessionCheckInterval: TimeInterval

    public init(applicationId: String,
                name: String = "",
                baseURL: String,
                requestMethod: RequestMethod = .post,
                payloadFlushFrequency: Int = 10,
                payloadPersistenceEnabled: Bool = true,
                encodeBase64: Bool = true,
                sessionForegroundTimeout: TimeInterval = 600,
                sessionBackgroundTimeout: TimeInterval = 300,
                sessionCheckInterval: TimeInterval = 15) {
      self.applicationId = applicationId
      self.name = name
      self.baseURL = baseURL
      self.requestMethod = requestMethod
      self.payloadFlushFrequency = payloadFlushFrequency
      self.payloadPersistenceEnabled = payloadPersistenceEnabled
      self.encodeBase64 = encodeBase64
      self.sessionForegroundTimeout = sessionForegroundTimeout
      self.sessionBackgroundTimeout = sessionBackgroundTimeout
      self.sessionCheckInterval = sessionCheckInterval
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
  private let trackerVersion = "2.1.1"

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

  @MainActor
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
    self.isBase64Encoded = configuration.encodeBase64
    self.session = Session()
    self.session.foregroundTimeout = max(configuration.sessionForegroundTimeout, 1)
    self.session.backgroundTimeout = max(configuration.sessionBackgroundTimeout, 1)
    self.session.interval = max(configuration.sessionCheckInterval, 1)

    if Tracker.isLoggerEnabled(for: .tracker) {
      logger.info("❄️ Tracker initialized.")
    }
  }
}

// MARK: - Tracking

@MainActor
extension Tracker {
  func track(payload: Payload,
             contexts: [SelfDescribingJSON]? = nil,
             timestamp: TimeInterval? = nil) async {
    let eventId = UUID().uuidString.lowercased()
    let timestamp = Int((timestamp ?? Date().timeIntervalSince1970) * 1000)
    let sessionContext = await session.sessionContext(with: eventId)
    let platformContext = await platformContext()
    let applicationContext = applicationContext()

    let allContexts: [SelfDescribingJSON] = (contexts ?? .init()) + [
      sessionContext,
      platformContext,
      applicationContext
    ].compactMap { $0 }

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

    var content: SnowplowDictionary = [:]
    content[.event] = EventType.unstructured.rawValue
    if isBase64Encoded {
      guard let eventValue = json.base64EncodedRepresentation else {
        if Tracker.isLoggerEnabled(for: .tracker) {
          logger.error("❄️ Failed to encode the data.")
        }

        return
      }
      content[.unstructuredEncoded] = eventValue
    } else {
      content[.unstructured] = json.dictionaryRepresentation
    }

    let payload = Payload(content, base64Encoded: isBase64Encoded)
    await track(payload: payload, contexts: contexts, timestamp: timestamp)
  }
}

// MARK: - Context

@MainActor
extension Tracker {
  private func applicationContext() -> SelfDescribingJSON? {
    guard
      let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
      let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    else {
      return nil
    }

    let dictionary: SnowplowDictionary = [
      .applicationBuild: build,
      .applicationVersion: version
    ]
    return SelfDescribingJSON(schema: .application, dictionary: dictionary)
  }

  private func platformContext() async -> SelfDescribingJSON {
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
