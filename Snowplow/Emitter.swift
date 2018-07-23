//
//  Emitter.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-04-05.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation

protocol EmitterDelegate: class {
    func emitter(_ emitter: Emitter, didFlush success: Bool)
}

class Emitter {

    init(baseURL: String, requestMethod: RequestMethod = .post, delegate: EmitterDelegate? = nil) {
        self.baseURL = baseURL
        self.requestMethod = requestMethod
        self.delegate = delegate
    }

    func input(_ payload: Payload) {
        payloads.append(payload)
        flushIfNeeded()
    }

    weak var delegate: EmitterDelegate?

    // MARK: - Private

    private let baseURL: String
    private let requestMethod: RequestMethod
    private lazy var payloads = [Payload]()
    private lazy var operationQueue = OperationQueue(with: "com.snowplow.emitter")

}

// MARK: - Flush

extension Emitter {

    private func needsFlush() -> Bool {
        return requestMethod == .get || payloads.count >= payloadFlushFrequency
    }

    private func flushIfNeeded() {
        guard needsFlush() else { return }
        flush()
    }

    private func flush(_ completion: ((_ error: Error?) -> Void)? = nil) {
        var requests = [NetworkRequest]()
        switch requestMethod {
        case .get:
            payloads.forEach { (payload) in
                let request = NetworkRequest()
                request.endpoint = "\(baseURL)/i"
                request.method = .get
                request.parameters = payload.values
                requests.append(request)
            }

        case .post:
            let request = NetworkRequest()
            request.endpoint = "\(baseURL)/com.snowplowanalytics.snowplow/tp2"
            request.method = .post
            request.queryType = .json
            request.headers = ["content-type": "application/json; charset=utf-8"]
            request.parameters = [
                "schema": Constants.schema.payloadDataSchema,
                "data": payloads.map({ $0.values })
            ]
            requests.append(request)
        }

        requests.forEach { [operationQueue, delegate] (request) in
            request.completionBlock = {
                if request.error != nil {
                    operationQueue.cancelAllOperations()
                    delegate?.emitter(self, didFlush: false)
                    return
                }

                guard operationQueue.operationCount == 0 else { return }
                delegate?.emitter(self, didFlush: true)
            }
        }

        operationQueue.addOperations(requests, waitUntilFinished: false)
    }

}

extension Emitter {

    enum RequestMethod {
        case get
        case post
    }

}

let payloadFlushFrequency = 10
