import Foundation
import OSLog

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@MainActor
class Session {
  var foregroundTimeout: TimeInterval = 600
  var backgroundTimeout: TimeInterval = 300
  var interval: TimeInterval = 15 {
    didSet {
      stopTracking()
      startTracking()
    }
  }

  private let logger: Logger = .init(subsystem: "SnowplowSwiftTracker", category: "Session")
  private let sessionFilename: String = "SnowplowSession.json"
  private var timer: Timer?
  private let state: SessionState

  // MARK: - Initialization

  init(info: SessionInfo? = nil) {
    let sessionFileURL: URL?

    do {
      let bundleId: String = Bundle.main.bundleIdentifier ?? ""
      var url = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      url.appendPathComponent("Snowplow/\(bundleId)/\(sessionFilename)")
      sessionFileURL = url
    } catch {
      sessionFileURL = nil
      if Tracker.isLoggerEnabled(for: .session) {
        logger.debug("❄️ Failed to resolve session file URL: \(error).")
      }
    }

    state = SessionState(initialInfo: info, sessionFileURL: sessionFileURL)

#if os(macOS)
    NotificationCenter.default.addObserver(self, selector: #selector(saveSessionOnLifecycle), name: NSApplication.willResignActiveNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(saveSessionOnLifecycle), name: NSApplication.willTerminateNotification, object: nil)
#else
    NotificationCenter.default.addObserver(self, selector: #selector(saveSessionOnLifecycle), name: UIApplication.willResignActiveNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(saveSessionOnLifecycle), name: UIApplication.willTerminateNotification, object: nil)
#endif

    if Tracker.isLoggerEnabled(for: .session) {
      logger.info("❄️ Session created.")
    }

    startTracking()
  }

  // MARK: - Tracking

  func startTracking() {
    if timer != nil {
      stopTracking()
    }
    timer = Timer.scheduledTimer(timeInterval: interval,
                                 target: self,
                                 selector: #selector(resetIfNeededTimerFired),
                                 userInfo: nil,
                                 repeats: true)

    if Tracker.isLoggerEnabled(for: .session) {
      logger.info("❄️ Session tracking started.")
    }
  }

  func stopTracking() {
    guard timer != nil else { return }
    timer?.invalidate()
    timer = nil

    if Tracker.isLoggerEnabled(for: .session) {
      logger.info("❄️ Session tracking stopped.")
    }
  }

  // MARK: - Session

  @objc private func resetIfNeededTimerFired(_ timer: Timer) {
    Task { [weak self] in
      await self?.resetIfNeeded()
    }
  }

  private func resetIfNeeded() async {
#if os(macOS)
    let isBackground = !NSApplication.shared.isActive
#else
    let isBackground = UIApplication.shared.applicationState == .background
#endif

    guard await state.shouldReset(isBackground: isBackground,
                                  foregroundTimeout: foregroundTimeout,
                                  backgroundTimeout: backgroundTimeout) else {
      return
    }

    await state.reset()
    await saveSession()

    if Tracker.isLoggerEnabled(for: .session) {
      logger.info("❄️ Session reset.")
    }
  }

  // MARK: - Info

  func sessionContext(with eventId: String) async -> SelfDescribingJSON {
    await state.sessionContext(with: eventId)
  }
}

// MARK: - Persistence

extension Session {

  @objc private func saveSessionOnLifecycle() {
    Task { [weak self] in
      await self?.saveSession()
    }
  }

  private func saveSession() async {
    do {
      try await state.save()

      if Tracker.isLoggerEnabled(for: .session) {
        logger.info("❄️ Session saved.")
      }
    } catch SessionState.PersistenceError.missingFileURL {
      if Tracker.isLoggerEnabled(for: .session) {
        logger.error("❄️ Cannot save sessions: no session file URL.")
      }
    } catch {
      if Tracker.isLoggerEnabled(for: .session) {
        logger.error("❄️ Failed to save session: \(error)")
      }
    }
  }
}

// MARK: - Session State

private actor SessionState {
  enum PersistenceError: Error {
    case missingFileURL
  }

  private var lastAccessTime: TimeInterval
  private var sessionInfo: SessionInfo
  private let sessionFileURL: URL?

  init(initialInfo: SessionInfo?, sessionFileURL: URL?) {
    self.sessionFileURL = sessionFileURL
    self.lastAccessTime = Date().timeIntervalSince1970

    var resolvedInfo = initialInfo
    if resolvedInfo == nil, let sessionFileURL {
      resolvedInfo = SessionInfo(from: sessionFileURL)
    }

    resolvedInfo?.update()

    self.sessionInfo = resolvedInfo ?? SessionInfo(userId: UUID().uuidString.lowercased(),
                                                   currentId: UUID().uuidString.lowercased(),
                                                   previousId: nil,
                                                   index: 0)
  }

  func shouldReset(isBackground: Bool,
                   foregroundTimeout: TimeInterval,
                   backgroundTimeout: TimeInterval,
                   now: TimeInterval = Date().timeIntervalSince1970) -> Bool {
    let timeout = isBackground ? backgroundTimeout : foregroundTimeout
    return now - lastAccessTime > timeout
  }

  func reset(now: TimeInterval = Date().timeIntervalSince1970) {
    sessionInfo.update()
    lastAccessTime = now
  }

  func sessionContext(with eventId: String) -> SelfDescribingJSON {
    let data: SnowplowDictionary = [
      .sessionContextUserId: sessionInfo.userId,
      .sessionContextSessionId: sessionInfo.currentId,
      .sessionContextPreviousSessionId: sessionInfo.previousId ?? NSNull(),
      .sessionContextSessionIndex: sessionInfo.index,
      .sessionContextFirstEventId: eventId,
      .sessionContextStorageMechanism: sessionInfo.storage
    ]
    return SelfDescribingJSON(schema: .session, dictionary: data)
  }

  func save() throws {
    guard let sessionFileURL else {
      throw PersistenceError.missingFileURL
    }

    var savedSessionInfo = sessionInfo
    savedSessionInfo.previousId = nil
    try savedSessionInfo.write(to: sessionFileURL)
  }
}
