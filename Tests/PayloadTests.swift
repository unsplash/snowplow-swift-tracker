import Foundation
import Testing
@testable import Snowplow

struct PayloadTests {
  let payload: Payload = {
    let content: SnowplowDictionary = [
      .action: "testAction",
      .event: "testEvent",
      .category: "testCategory",
      .property: "testProperty",
      .value: 8
    ]
    return Payload(content, base64Encoded: false)
  }()

  @Test("Payload")
  func testPayload() async throws {
    #expect((payload.content[.action] as? String) == "testAction")
    #expect((payload.content[.event] as? String) == "testEvent")
    #expect((payload.content[.category] as? String) == "testCategory")
    #expect((payload.content[.property] as? String) == "testProperty")
    #expect((payload.content[.value] as? Int) == 8)
  }

  @Test("Encoding")
  func testEncoding() async throws {
    let data = try JSONSerialization.data(withJSONObject: payload.dictionaryRepresentation)

    let decodedPayload = Payload(data: data)
    #expect(decodedPayload != nil)
  }
}
