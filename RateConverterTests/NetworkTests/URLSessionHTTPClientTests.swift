//
//  URLSessionHTTPClientTests.swift
//  RateConverterTests
//
//  Created by 黃昭銘 on 2025/7/3.
//

import Foundation
import XCTest

@testable import RateConverter

// MARK: - MockURLProtocol
final class MockURLProtocol: URLProtocol {
    
    static var stubResponseData: Data?
    static var stubStatusCode: Int = 200
    
    override class func canInit(with request: URLRequest) -> Bool { true }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    
    override func startLoading() {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: Self.stubStatusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        
        if let data = Self.stubResponseData {
            client?.urlProtocol(self, didLoad: data)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

// MARK: - URLSessionHTTPClientTests
final class URLSessionHTTPClientTests: XCTestCase {
    var client: URLSessionHTTPClient!
    
    override func setUp() {
        super .setUp()
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        
        client = URLSessionHTTPClient(session: session)
    }
    
    func test_request_shouldReturnSuccessDataAndResponse() {
        let expectedData = "{\"key\":\"value\"}".data(using: .utf8)!
        MockURLProtocol.stubResponseData = expectedData
        MockURLProtocol.stubStatusCode = 200
        
        let request = DummyRequest()
        let expectation = self.expectation(description: "Wait for result")
        
        client.request(with: request) { result in
            switch result {
            case .success(let data, let response):
                XCTAssertEqual(data, expectedData)
                XCTAssertEqual(response.statusCode, 200)
            case .failure:
                XCTFail("Request should succeed")
            }
            expectation.fulfill()
        }
    
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_request_shouldReturnResponseErrorWhenFail() {
        MockURLProtocol.stubResponseData = nil
        MockURLProtocol.stubStatusCode = 500
        
        let request = DummyRequest()
        let expectation = self.expectation(description: "Wait for result")
        
        client.request(with: request) { result in
            switch result {
            case .success:
                XCTFail("Request should fail")
            case .failure(let error):
                XCTAssertEqual(error, .responseError)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - DummyRequest
struct DummyRequest: RequestType {
    var baseURL: URL = URL(string: "https://test.com")!
    var path: String = "/test"
    var queryItems: [URLQueryItem] = []
    var method: RateConverter.HTTPMethod = .get
    var body: Data? = nil
    var headers: [String : String]? = nil
}
