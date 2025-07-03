//
//  RequestTests.swift
//  RateConverterTests
//
//  Created by 黃昭銘 on 2025/7/3.
//

import Foundation
import XCTest

@testable import RateConverter

final class RequestTests: XCTestCase {
    
    struct TestRequest: RequestType {
        var baseURL: URL
        var path: String
        var queryItems: [URLQueryItem]
        var method: RateConverter.HTTPMethod
        var body: Data?
        var headers: [String : String]?
    }
    
    func test_FullURL_shouldIncludePathAndQuery() {
        let baseURL = URL(string: "https://openexchangerates.org/api/")!
        let request = TestRequest(
            baseURL: baseURL,
            path: "currencies.json",
            queryItems: [URLQueryItem(name: "app_id", value: "TEST_APP_ID")],
            method: .get,
            body: nil,
            headers: nil
        )
        let expected = "https://openexchangerates.org/api/currencies.json?app_id=TEST_APP_ID"
        XCTAssertEqual(request.fullURL.absoluteString, expected)
    }
    
    func test_urlRequest_shouldUseCorrectHTTPMethod() {
        let baseURL = URL(string: "https://example.com")!
        let request = TestRequest(
            baseURL: baseURL,
            path: "test.json",
            queryItems: [],
            method: .get,
            body: nil,
            headers: nil
        )
        XCTAssertEqual(request.urlRequest.httpMethod, "GET")
    }
    
    func test_urlRequest_shouldIncludeHTTPBody() {
        let body = try! JSONSerialization.data(withJSONObject: ["base": "USD"])
        let request = TestRequest(
            baseURL: URL(string: "https://openexchangerates.org/api/")!,
            path: "convert.json",
            queryItems: [],
            method: .post,
            body: body,
            headers: nil
        )
        XCTAssertEqual(request.urlRequest.httpBody, body)
    }
    
    func test_urlRequest_shouldIncludeHeaders() {
        let request = TestRequest(
            baseURL: URL(string: "https://openexchangerates.org/api/")!,
            path: "latest.json",
            queryItems: [],
            method: .get,
            body: nil,
            headers: ["Authorization": "Bearer TOKEN"]
        )
        let headerValue = request.urlRequest.value(forHTTPHeaderField: "Authorization")
        XCTAssertEqual(headerValue, "Bearer TOKEN")
    }
}
