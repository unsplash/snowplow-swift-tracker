//
//  Session.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-06-08.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation
import os.log

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public class Session {
  var foregroundTimeout: TimeInterval = 600
  var backgroundTimeout: TimeInterval = 300
  var interval: TimeInterval = 15 {
    didSet {
      stopTracking()
      startTracking()
    }
  }

  private let logger: Logger = .init(subsystem: "SnowplowSwiftTracker", category: "Session")
  private var lastAccessTime: TimeInterval
  private var sessionInfo: SessionInfo
  private let sessionFilename: String = "SnowplowSession.json"
  private var sessionFileURL: URL?
  private var timer: Timer?

  // MARK: - Initialization
  
  init(info: SessionInfo? = nil) {
    lastAccessTime = Date().timeIntervalSince1970
    
    var initialSessionInfo: SessionInfo? = info
    
    if initialSessionInfo == nil {
      do {
        let bundleId: String = Bundle.main.bundleIdentifier ?? ""
        var url = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        url.appendPathComponent("Snowplow/\(bundleId)/\(sessionFilename)")
        sessionFileURL = url
        
        initialSessionInfo = SessionInfo(from: url)
      } catch {
        logger.debug("Failed to load the previous session file: \(error).")
      }
    }
    
    initialSessionInfo?.update()
    
    sessionInfo = initialSessionInfo ?? SessionInfo(userId: UUID().uuidString.lowercased(),
                                                    currentId: UUID().uuidString.lowercased(),
                                                    previousId: nil,
                                                    index: 0)
    
#if os(macOS)
    NotificationCenter.default.addObserver(self, selector: #selector(saveSession), name: NSApplication.willResignActiveNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(saveSession), name: NSApplication.willTerminateNotification, object: nil)
#else
    NotificationCenter.default.addObserver(self, selector: #selector(saveSession), name: UIApplication.willResignActiveNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(saveSession), name: UIApplication.willTerminateNotification, object: nil)
#endif

    logger.info("Session created.")

    startTracking()
  }
  
  // MARK: - Tracking
  
  func startTracking() {
    if timer != nil {
      stopTracking()
    }
    timer = Timer.scheduledTimer(timeInterval: interval,
                                 target: self,
                                 selector: #selector(resetIfNeeded),
                                 userInfo: nil,
                                 repeats: true)

    logger.info("Session tracking started.")
  }
  
  func stopTracking() {
    guard timer != nil else { return }
    timer?.invalidate()
    timer = nil
    logger.info("Session tracking stopped.")
  }
  
  // MARK: - Session
  
  @objc @MainActor private func resetIfNeeded(_ timer: Timer) {
#if os(macOS)
    let isBackground = !NSApplication.shared.isActive
#else
    let isBackground = UIApplication.shared.applicationState == .background
#endif
    
    let timeout = isBackground ? backgroundTimeout : foregroundTimeout
    
    if Date().timeIntervalSince1970 - lastAccessTime > timeout {
      reset()
    }
  }
  
  private func update() {
    lastAccessTime = Date().timeIntervalSince1970
  }
  
  private func reset() {
    sessionInfo.update()
    update()
    saveSession()
    logger.info("Session reset.")
  }
  
  // MARK: - Info
  
  func sessionContext(with eventId: String) -> SelfDescribingJSON {
    var data: [PropertyKey: String] = [
      .sessionContextUserId: sessionInfo.userId,
      .sessionContextSessionId: sessionInfo.currentId,
      .sessionContextSessionIndex: String(sessionInfo.index),
      .sessionContextFirstEventId: eventId,
      .sessionContextStorageMechanism: sessionInfo.storage
    ]

    data[.sessionContextPreviousSessionId] = sessionInfo.previousId

    return SelfDescribingJSON(schema: .session, data: data)
  }
  
}

// MARK: - Persistence

extension Session {
  
  @objc private func saveSession() {
    guard let sessionFileURL else {
      logger.error("Cannot save sessions: no session file URL.")
      return
    }

    var savedSessionInfo = sessionInfo
    savedSessionInfo.previousId = nil
    savedSessionInfo.write(to: sessionFileURL)

    logger.info("Session saved.")
  }
}
