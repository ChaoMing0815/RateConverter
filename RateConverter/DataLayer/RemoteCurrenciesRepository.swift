//
//  RemoteCurrenciesRepository.swift
//  RateConverter
//
//  Created by 黃昭銘 on 2025/7/9.
//

import Foundation

enum RemoteCurrenciesRepositoryError: Error {
    case failedToGetLatestCurrencies
}

protocol RemoteCurrenciesRepositoryProtocol {
    func getCurrencies() async -> Result<RatesDTO, RemoteCurrenciesRepositoryError>
}

class RemoteCurrenciesRepository: RemoteCurrenciesRepositoryProtocol {
    let appID = "9655c63914c648e58c1ed5f8c97c61f6"
    let client: URLSessionHTTPClient
    init(client: URLSessionHTTPClient) {
        self.client = client
    }
    
    func getCurrencies() async -> Result<RatesDTO, RemoteCurrenciesRepositoryError> {
        let path = "latest.json"
        let queryItems = [URLQueryItem(name: "app_id", value: appID)]        
        let request = Request(baseURL: URL(string: "https://openexchangerates.org/api/")!, path: path, queryItems: queryItems, method: .get)
        
        return await withCheckedContinuation { continuation in
            client.request(with: request) { result in
                switch result {
                case let .success(data, _):
                    do {
                        let dto = try JSONDecoder().decode(RatesDTO.self, from: data)
                        continuation.resume(returning: .success(dto))
                    } catch {
                        continuation.resume(returning: .failure(.failedToGetLatestCurrencies))
                    }
                case .failure:
                    continuation.resume(returning: .failure(.failedToGetLatestCurrencies))
                }
            }
        }
    }
    
}
