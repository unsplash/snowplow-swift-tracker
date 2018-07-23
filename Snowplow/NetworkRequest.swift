//
//  NetworkRequest.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-04-05.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation

class NetworkRequest: ConcurrentOperation {

    enum Method: String {
        case get, post, put, delete
    }

    enum QueryType {
        case json, path
    }

    enum RequestError: Error {
        case invalidURL, noHTTPResponse, http(status: Int)

        var localizedDescription: String {
            switch self {
            case .invalidURL:
                return "Invalid URL."
            case .noHTTPResponse:
                return "Not a HTTP response."
            case .http(let status):
                return "HTTP error: \(status)."
            }
        }
    }

    var endpoint: String?
    var method: NetworkRequest.Method = .get
    var queryType: NetworkRequest.QueryType = .path
    var headers: [String: String]?
    var parameters: [String: Any]?

    // MARK: - Prepare the request

    func prepareURLRequest() throws -> URLRequest {
        guard let endpoint = endpoint, let url = URL(string: endpoint) else {
            throw RequestError.invalidURL
        }

        switch queryType {
        case .json:
            var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
            if let parameters = parameters {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
            }

            return request

        case .path:
            var query = ""

            parameters?.forEach { key, value in
                query = "\(query)\(key)=\(value)&"
            }

            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            components.query = query

            return URLRequest(url: components.url!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
        }
    }

    // MARK: - Execute the request

    override func main() {
        guard var request = try? prepareURLRequest() else {
            completeWithError(RequestError.invalidURL)
            return
        }

        request.allHTTPHeaderFields = headers
        request.httpMethod = method.rawValue

        let session = URLSession.shared
        task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            self.processResponse(response, data: data, error: error)
        })
        task?.resume()
    }

    override func cancel() {
        task?.cancel()
        super.cancel()
    }

    // MARK: - Process the response

    final func processResponse(_ response: URLResponse?, data: Data?, error: Error?) {
        if let error = error {
            return completeWithError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            return completeWithError(RequestError.noHTTPResponse)
        }

        processHTTPResponse(httpResponse, data: data)
    }

    final func processHTTPResponse(_ response: HTTPURLResponse, data: Data?) {
        let statusCode = response.statusCode

        if successCodes.contains(statusCode) {
            processResponseData(data)
        } else if failureCodes.contains(statusCode) {
            completeWithError(RequestError.http(status: statusCode))
        } else {
            // Server returned response with status code different than expected `successCodes`.
            let info = [
                NSLocalizedDescriptionKey: "Request failed with code \(statusCode)",
                NSLocalizedFailureReasonErrorKey: "Wrong handling logic, wrong endpoing mapping or backend bug."
            ]
            let error = NSError(domain: "NetworkService", code: 0, userInfo: info)
            completeWithError(error)
        }
    }

    func processResponseData(_ data: Data?) {
        completeOperation()
    }

    // MARK: - Private

    private var task: URLSessionDataTask?
    private var successCodes: CountableRange<Int> = 200..<299
    private var failureCodes: CountableRange<Int> = 400..<499

}
