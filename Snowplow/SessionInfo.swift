//
//  SessionInfo.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-06-11.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation

public struct SessionInfo: Codable {

    var userId: String
    var currentId: String
    var previousId: String?
    var index: Int
    var storage = "SQLITE"

    init(userId: String, currentId: String, previousId: String?, index: Int) {
        self.userId = userId
        self.currentId = currentId
        self.previousId = previousId
        self.index = index
    }

    init?(from url: URL) {
        guard let sessionData = try? Data(contentsOf: url),
            let sessionInfo = try? JSONDecoder().decode(SessionInfo.self, from: sessionData) else { return nil }

        userId = sessionInfo.userId
        currentId = sessionInfo.currentId
        previousId = sessionInfo.previousId
        index = sessionInfo.index
    }

    func write(to url: URL) {
        do {
            let sessionData = try JSONEncoder().encode(self)
            try sessionData.write(to: url, options: .atomic)
        } catch {
            debugPrint(error)
        }
    }

    mutating func update() {
        previousId = currentId
        currentId = UUID().uuidString.lowercased()
        index += 1
    }

}
