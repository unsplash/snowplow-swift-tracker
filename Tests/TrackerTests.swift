import Testing
@testable import Snowplow

@MainActor
struct TrackerTests {
  @Test("Tracker - ScreenView")
  func testScreenView() async {
    let tracker: Tracker = await {
      let emitter = await Emitter(
        baseURL: "http://localhost:9090",
        requestMethod: .post,
        payloadFlushFrequency: 1,
        payloadPersistenceEnabled: false
      )

      return Tracker(applicationId: "testAppId", emitter: emitter, name: "TestTracker")
    }()

    await tracker.trackScreenView(name: "Test Screen")
    await tracker.trackScreenView(name: "Test Screen", identifier: "screenId-123")
  }

  @Test("Tracker - Struct Events")
  func testStructEvent() async {
    let tracker: Tracker = await {
      let emitter = await Emitter(
        baseURL: "http://localhost:9090",
        requestMethod: .post,
        payloadFlushFrequency: 1,
        payloadPersistenceEnabled: false
      )

      return Tracker(applicationId: "testAppId", emitter: emitter, name: "TestTracker")
    }()

    await tracker.trackStructEvent(category: "testCategory", action: "testAction")
    await tracker.trackStructEvent(category: "testCategory", action: "testAction", label: "testLabel")
    await tracker.trackStructEvent(category: "testCategory", action: "testAction", label: "testLabel", property: "testProperty")
    await tracker.trackStructEvent(category: "testCategory", action: "testAction", label: "testLabel", property: "testProperty", value: 8)
  }
}
