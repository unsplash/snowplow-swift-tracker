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

    let storage = PayloadStorage(persistenceEnabled: false)
    await storage.append(payload)

    await #expect(storage.payloadCount == 1)

    await storage.remove([payload])

    await #expect(storage.payloadCount == 0)
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
    let storage = PayloadStorage(persistenceEnabled: true)
    await storage.append(payload)

    let newStorage = PayloadStorage(persistenceEnabled: true)
    await #expect(newStorage.payloadCount == 1)
    await newStorage.removeAll()
  }
}
