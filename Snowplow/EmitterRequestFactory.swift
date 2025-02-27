//
//  EmitterRequestFactory.swift
//  Snowplow
//
//  Created by Olivier Collet on 2023-06-27.
//  Copyright © 2023 Unsplash. All rights reserved.
//

import Foundation

struct EmitterRequestFactory: Sendable {
  let baseURL: String
  var timeoutInterval = 30.0
  
  func getRequest(for payload: Payload) throws -> URLRequest {
    guard let endpointURL = URL(string: "\(baseURL)/i") else {
      throw URLError(.badURL)
    }
    
    guard var components = URLComponents(url: endpointURL, resolvingAgainstBaseURL: true) else {
      throw URLError(.badURL)
    }
    components.queryItems = payload.content.queryItems

    guard let url = components.url else {
      throw URLError(.badURL)
    }
    
    var request: URLRequest = .init(url: url,
                                    cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                    timeoutInterval: timeoutInterval)
    request.httpMethod = "GET"
    
    return request
  }
  
  func postRequest(for payloads: [Payload]) throws -> URLRequest {
    guard let endpointURL = URL(string: "\(baseURL)/com.snowplowanalytics.snowplow/tp2") else {
      throw URLError(.badURL)
    }

    let finalJSONPayload = SelfDescribingJSON.dictionaryRepresentation(schema: .payloadData, data: payloads.map { $0.content.dictionaryRepresentation })

    var request: URLRequest = .init(url: endpointURL,
                                    cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                    timeoutInterval: timeoutInterval)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = ["content-type": "application/json; charset=utf-8"]
    request.httpBody = try JSONSerialization.data(withJSONObject: finalJSONPayload)

    return request
  }
}
