import Foundation
import Testing
@testable import Snowplow

struct PayloadStorageTests {
  @Test("Add/Remove Payload")
  func testStorage() async {
    let content: SnowplowDictionary = [
      .action: "testAction",
      .event: "testEvent",
      .category: "testCategory",
      .property: "testProperty",
      .value: 8
    ]
    let payload = Payload(content, base64Encoded: false)

    let emitter = Emitter(baseURL: "http://localhost:9090",
                                requestMethod: .post,
                                payloadFlushFrequency: 100,
                                payloadPersistenceEnabled: false)

    await emitter.input(payload)
    await #expect(emitter.storedPayloadCount == 1)

    await emitter.removeAllStoredPayloads()
    await #expect(emitter.storedPayloadCount == 0)
  }

  @Test("Persistence")
  func testPersistence() async {
    let content: SnowplowDictionary = [
      .action: "testAction",
      .event: "testEvent",
      .category: "testCategory",
      .property: "testProperty",
      .value: 8
    ]
    let payload = Payload(content, base64Encoded: false)

    let emitter = Emitter(baseURL: "http://localhost:9090",
                                requestMethod: .post,
                                payloadFlushFrequency: 100,
                                payloadPersistenceEnabled: true)
    await emitter.input(payload)

    let newEmitter = Emitter(baseURL: "http://localhost:9090",
                                   requestMethod: .post,
                                   payloadFlushFrequency: 100,
                                   payloadPersistenceEnabled: true)
    await #expect(newEmitter.storedPayloadCount == 1)
    await newEmitter.removeAllStoredPayloads()
  }
}
