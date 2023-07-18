//
//  PayloadStorage.swift
//  Snowplow
//
//  Created by Olivier Collet on 2023-07-17.
//  Copyright © 2023 Unsplash. All rights reserved.
//

import Foundation
import OSLog

actor PayloadStorage {
    var payloadCount: Int { payloads.count }

    private let isPayloadPersistenceEnabled: Bool
    private var cacheFilename = "SnowplowEmitterPayloads.data"
    private(set) var payloads: [Payload] = []

    init(payloadPersistenceEnabled: Bool = true) {
        isPayloadPersistenceEnabled = payloadPersistenceEnabled
        guard payloadPersistenceEnabled else { return }

        let fileURL = URL(appFolder: .caches).appendingPathComponent(cacheFilename)
        guard FileManager().fileExists(atPath: fileURL.path) else { return }

        do {
            let encodedPayloads = try Data(contentsOf: fileURL)
            payloads = try JSONDecoder().decode([Payload].self, from: encodedPayloads)
        } catch {
            os_log("%@", log: OSLog.default, type: OSLogType.error, error.localizedDescription)
        }
    }

    func save() {
        guard isPayloadPersistenceEnabled else { return }
        let fileURL = URL(appFolder: .caches).appendingPathComponent(cacheFilename)

        do {
            let encodedPayloads = try JSONEncoder().encode(payloads)
            try encodedPayloads.write(to: fileURL, options: .atomic)
        } catch {
            os_log("%@", log: OSLog.default, type: OSLogType.error, error.localizedDescription)
        }
    }

    func append(_ payload: Payload) {
        payloads.append(payload)
        save()
    }

    func remove(payloads: [Payload]) {
        payloads.forEach { payload in
            guard let index = self.payloads.firstIndex(of: payload) else { return }
            self.payloads.remove(at: index)
        }
        save()
    }
}
