# snowplow-swift-tracker

[Snowplow](http://snowplowanalytics.com) event tracker for Apple platforms written in Swift.

## Installation

The Snowplow Swift Tracker is available through [Swift Package Manager](https://github.com/apple/swift-package-manager). You can follow the [guide published by Apple](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app) to add it to your Xcode project.

## Usage

Events are sent through an instance of `Tracker`.

```
let tracker = Tracker(
  configuration: .init(
    applicationId: "APP_ID",
    baseURL: "SNOWPLOW_URL"
  )
)
```

## Testing

The tracker tests need to be validated using an instance of [Snowplow Micro](https://docs.snowplow.io/docs/data-product-studio/data-quality/snowplow-micro/) running locally.
The easiest way to run Snowplow Micro locally is with Docker and [Colima](https://github.com/abiosoft/colima).

Install Docker and Colima via [Homebrew](https://brew.sh):

```
# Install Docker
brew install docker-credential-helper docker

# Install Colima
brew install colima
```

To run Snowplow Micro:

```
# Start Colima
colima start

# Run Snowplow Micro
docker run -p 9090:9090 snowplow/snowplow-micro:2.1.3-distroless

# Stop Colima
colima stop
```

Open Snowplow Micro in a web browser to validate the payloads sent from the tracker:
[`http://localhost:9090/micro/ui/`](http://localhost:9090/micro/ui/)
