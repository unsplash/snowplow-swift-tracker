import Foundation

public enum SchemaDefinition: String, Codable, Sendable {
  case contexts        = "iglu:com.snowplowanalytics.snowplow/contexts/jsonschema/1-0-1"
  case platformMobile  = "iglu:com.snowplowanalytics.snowplow/mobile_context/jsonschema/1-0-1"
  case platformDesktop = "iglu:com.snowplowanalytics.snowplow/desktop_context/jsonschema/1-0-0"
  case payloadData     = "iglu:com.snowplowanalytics.snowplow/payload_data/jsonschema/1-0-0"
  case screenView      = "iglu:com.snowplowanalytics.snowplow/screen_view/jsonschema/1-0-0"
  case session         = "iglu:com.snowplowanalytics.snowplow/client_session/jsonschema/1-0-1"
  case unstructedEvent = "iglu:com.snowplowanalytics.snowplow/unstruct_event/jsonschema/1-0-0"
}
