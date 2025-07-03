//
//  HTTPClient.swift
//  RateConverter
//
//  Created by 黃昭銘 on 2025/7/1.
//

import Foundation

public enum HTTPClientError: Error {
    case jsonToDataError
    case responseError
    case cannotFindDataOrResponse
    case HTTPMethodShouldBePOST
}

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(HTTPClientError)
}

public protocol HTTPClient {
    func request(with request: RequestType, completion: @escaping (HTTPClientResult) -> Void)
}
