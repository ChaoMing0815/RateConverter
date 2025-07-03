//
//  URLSessionHTTPClient.swift
//  RateConverter
//
//  Created by 黃昭銘 on 2025/7/2.
//

import Foundation

public class URLSessionHTTPClient: NSObject, HTTPClient {
    
    private let session: URLSession
    
    public init(session: URLSession) {
        self.session = session
    }
    
    public func request(with request: RequestType, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: request.urlRequest) { data, response, error in
            if let _ = error {
                completion(.failure(.responseError))
                return
            }
            guard let data,
                  let response = response as? HTTPURLResponse
            else {
                completion(.failure(.cannotFindDataOrResponse))
                return
            }
            completion(.success(data, response))
        }.resume()
    }
}
