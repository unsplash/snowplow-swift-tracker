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
    var payloadFlushFrequency = 10

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
        flush { [unowned self] (error) in
            if let error = error {
                debugPrint(error)
            }
            self.delegate?.emitter(self, didFlush: error == nil)
        }
    }

    private func flush(_ completion: ((_ error: Error?) -> Void)? = nil) {
        switch requestMethod {
        case .get:
            payloads.forEach { [unowned self] (payload) in
                let request = NetworkRequest()
                request.endpoint = "\(baseURL)/i"
                request.method = .get
                request.parameters = payload.content
                request.completionBlock = {
                    if let error = request.error {
                        completion?(error)
                        return
                    }
                    if let index = self.payloads.index(of: payload) {
                        self.payloads.remove(at: index)
                    }
                    completion?(nil)
                }
                operationQueue.addOperationWithDependencies(request)
            }

        case .post:
            let payloads = self.payloads
            let request = NetworkRequest()
            request.endpoint = "\(baseURL)/com.snowplowanalytics.snowplow/tp2"
            request.method = .post
            request.queryType = .json
            request.headers = ["content-type": "application/json; charset=utf-8"]
            request.parameters = SelfDescribingJSON(schema: .payloadData, data: payloads).dictionaryRepresentation
            request.completionBlock = {
                if let error = request.error {
                    completion?(error)
                    return
                }
                for payload in payloads {
                    if let index = self.payloads.index(of: payload) {
                        self.payloads.remove(at: index)
                    }
                }
                completion?(nil)
            }
            operationQueue.addOperationWithDependencies(request)
        }
    }

}

extension Emitter {

    enum RequestMethod {
        case get
        case post
    }

}
