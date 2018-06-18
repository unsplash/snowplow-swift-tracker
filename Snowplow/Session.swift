//
//  Session.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-06-08.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation
import UIKit

private let sessionFilename = "SnowplowSession.json"
#if os(tvOS)
private let sessionFileURL = URL(fileURLWithPath: "\(NSTemporaryDirectory())/\(sessionFilename)")
#else
private let sessionFileURL = URL(appFolder: .applicationSupport).appendingPathComponent(sessionFilename)
#endif

class Session {

    // MARK: - Public properties

    var foregroundTimeout: TimeInterval = 600
    var backgroundTimeout: TimeInterval = 300
    var interval: TimeInterval = 15 {
        didSet {
            stopTracking()
            startTracking()
        }
    }

    // MARK: - Private properties

    private var sessionInfo: SessionInfo
    private var timer: Timer?
    private var lastAccessTime: TimeInterval

    // MARK: - Initialization

    init() {
        lastAccessTime = Date().timeIntervalSince1970
        sessionInfo = SessionInfo(from: sessionFileURL) ?? SessionInfo(userId: UUID().uuidString.lowercased(),
                                                                       currentId: UUID().uuidString.lowercased(),
                                                                       previousId: nil,
                                                                       index: 0)
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
    }

    func stopTracking() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Session

    @objc private func resetIfNeeded(_ timer: Timer) {
        let isBackground = UIApplication.shared.applicationState == .background
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
    }

    // MARK: - Info

    func sessionContext(with eventId: String) -> SelfDescribingJSON {
        let data: [PropertyKey: Any] = [
            .sessionContextUserId: sessionInfo.userId,
            .sessionContextSessionId: sessionInfo.currentId,
            .sessionContextPreviousSessionId: sessionInfo.previousId ?? NSNull(),
            .sessionContextSessionIndex: sessionInfo.index,
            .sessionContextFirstEventId: eventId,
            .sessionContextStorageMechanism: sessionInfo.storage
        ]
        return SelfDescribingJSON(schema: .session, data: data)
    }

}

// MARK: - Persistence

extension Session {

    private func saveSession() {
        var savedSessionInfo = sessionInfo
        savedSessionInfo.previousId = nil
        savedSessionInfo.write(to: sessionFileURL)
    }

}
