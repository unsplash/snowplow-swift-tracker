import Foundation

struct EmitterRequestFactory: Sendable {
  let baseURL: String
  var timeoutInterval = 30.0
  
  func getRequest(for payload: Payload) throws -> URLRequest {
    guard let baseEndpointURL = URL(string: baseURL) else {
      throw URLError(.badURL)
    }

    let endpointURL = baseEndpointURL.appendingPathComponent("i")
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
    guard let baseEndpointURL = URL(string: baseURL) else {
      throw URLError(.badURL)
    }
    let endpointURL = baseEndpointURL
      .appendingPathComponent("com.snowplowanalytics.snowplow")
      .appendingPathComponent("tp2")

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
