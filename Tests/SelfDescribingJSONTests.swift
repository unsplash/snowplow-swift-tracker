import Foundation
import Testing
@testable import Snowplow

struct SelfDescribingJSONTests {
  @Test("Data Initializer")
  func testDataInitializer() {
    let selfDescribedJSON = SelfDescribingJSON(schema: .session, data: [
      "key": "value"
    ])

    #expect(selfDescribedJSON.schema == .session)
    #expect((selfDescribedJSON.data["key"] as? String) == "value")
  }

  @Test("Encoding")
  func testEncoding() throws {
    let selfDescribedJSON = SelfDescribingJSON(schema: .screenView, data: [
      "key": "value"
    ])
    let data = try JSONSerialization.data(withJSONObject: selfDescribedJSON.dictionaryRepresentation)

    let decodedSelfDescribedJSON = SelfDescribingJSON(data: data)
    #expect(decodedSelfDescribedJSON != nil)

    let schema = decodedSelfDescribedJSON!.schema
    #expect(schema == .screenView)

    let decodedData = decodedSelfDescribedJSON!.data
    #expect(decodedData is [String: String])

    let dictionary = decodedData as! [String: String]
    #expect(dictionary["key"] == "value")
  }
}
