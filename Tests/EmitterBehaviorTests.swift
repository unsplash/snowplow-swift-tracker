import Foundation
import Testing
@testable import Snowplow

private final class URLProtocolMock: URLProtocol {
  typealias RequestHandler = (URLRequest) throws -> (HTTPURLResponse, Data?)

  private static let lock = NSLock()
  nonisolated(unsafe) private static var _requests: [URLRequest] = []
  nonisolated(unsafe) private static var _handler: RequestHandler = { request in
    let response = HTTPURLResponse(url: try #require(request.url),
                                   statusCode: 200,
                                   httpVersion: nil,
                                   headerFields: nil)!
    return (response, nil)
  }

  static var requests: [URLRequest] {
    lock.lock()
    defer { lock.unlock() }
    return _requests
  }

  static func reset() {
    lock.lock()
    defer { lock.unlock() }
    _requests = []
  }

  static func setHandler(_ handler: @escaping RequestHandler) {
    lock.lock()
    defer { lock.unlock() }
    _handler = handler
  }

  override class func canInit(with request: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    let handler: RequestHandler

    Self.lock.lock()
    Self._requests.append(request)
    handler = Self._handler
    Self.lock.unlock()

    do {
      let (response, data) = try handler(request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      if let data {
        client?.urlProtocol(self, didLoad: data)
      }
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}

@Suite(.serialized)
struct EmitterBehaviorTests {
  @Test("Tracker sends ue_px when base64 encoding is enabled")
  @MainActor
  func testTrackerSendsBase64UnstructuredEvent() async throws {
    URLProtocol.registerClass(URLProtocolMock.self)
    defer { URLProtocol.unregisterClass(URLProtocolMock.self) }

    URLProtocolMock.reset()
    URLProtocolMock.setHandler { request in
      let response = HTTPURLResponse(url: try #require(request.url),
                                     statusCode: 200,
                                     httpVersion: nil,
                                     headerFields: nil)!
      return (response, nil)
    }

    let tracker = Tracker(configuration: .init(applicationId: "test",
                                               baseURL: "https://collector.example.com",
                                               payloadFlushFrequency: 1,
                                               payloadPersistenceEnabled: false,
                                               encodeBase64: true))

    await tracker.trackScreenView(name: "Screen A")

    let capturedRequest = try #require(URLProtocolMock.requests.last(where: {
      $0.url?.host == "collector.example.com"
    }))
    let payloadItem = try parseFirstPayloadItem(from: capturedRequest)
    #expect(payloadItem["e"] as? String == "ue")
    #expect(payloadItem["ue_px"] is String)
    #expect(payloadItem["ue_pr"] == nil)
  }

  @Test("Tracker sends ue_pr when base64 encoding is disabled")
  @MainActor
  func testTrackerSendsPlainUnstructuredEvent() async throws {
    URLProtocol.registerClass(URLProtocolMock.self)
    defer { URLProtocol.unregisterClass(URLProtocolMock.self) }

    URLProtocolMock.reset()
    URLProtocolMock.setHandler { request in
      let response = HTTPURLResponse(url: try #require(request.url),
                                     statusCode: 200,
                                     httpVersion: nil,
                                     headerFields: nil)!
      return (response, nil)
    }

    let tracker = Tracker(configuration: .init(applicationId: "test",
                                               baseURL: "https://collector.example.com",
                                               payloadFlushFrequency: 1,
                                               payloadPersistenceEnabled: false,
                                               encodeBase64: false))

    await tracker.trackScreenView(name: "Screen B")

    let capturedRequest = try #require(URLProtocolMock.requests.last(where: {
      $0.url?.host == "collector.example.com"
    }))
    let payloadItem = try parseFirstPayloadItem(from: capturedRequest)
    #expect(payloadItem["e"] as? String == "ue")
    #expect(payloadItem["ue_pr"] is [String: Any])
    #expect(payloadItem["ue_px"] == nil)
  }

  @Test("Emitter keeps payloads when server responds with non-2xx status")
  func testEmitterRetainsPayloadOnServerError() async throws {
    URLProtocol.registerClass(URLProtocolMock.self)
    defer { URLProtocol.unregisterClass(URLProtocolMock.self) }

    URLProtocolMock.reset()
    URLProtocolMock.setHandler { request in
      let response = HTTPURLResponse(url: try #require(request.url),
                                     statusCode: 500,
                                     httpVersion: nil,
                                     headerFields: nil)!
      return (response, nil)
    }

    let emitter = Emitter(baseURL: "https://collector.example.com",
                          requestMethod: .post,
                          payloadFlushFrequency: 1,
                          payloadPersistenceEnabled: false)

    let payload: SnowplowDictionary = [.event: "se", .category: "cat", .action: "act"]
    await emitter.input(Payload(payload, base64Encoded: false))

    await #expect(emitter.storedPayloadCount == 1)
  }

  private func parseFirstPayloadItem(from request: URLRequest) throws -> [String: Any] {
    let body = try #require(requestBodyData(from: request))
    let root = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
    let data = try #require(root["data"] as? [[String: Any]])
    return try #require(data.first)
  }

  private func requestBodyData(from request: URLRequest) -> Data? {
    if let body = request.httpBody {
      return body
    }

    guard let stream = request.httpBodyStream else {
      return nil
    }

    stream.open()
    defer { stream.close() }

    let bufferSize = 4096
    var data = Data()
    var buffer = [UInt8](repeating: 0, count: bufferSize)

    while stream.hasBytesAvailable {
      let readCount = stream.read(&buffer, maxLength: bufferSize)
      if readCount < 0 {
        return nil
      }
      if readCount == 0 {
        break
      }
      data.append(buffer, count: readCount)
    }

    return data
  }
}
