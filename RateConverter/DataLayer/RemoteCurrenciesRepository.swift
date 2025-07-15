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
    func getCurrencies() async throws -> Result<RatesDTO, RemoteCurrenciesRepositoryError>
}

class RemoteCurrenciesRepository: RemoteCurrenciesRepositoryProtocol {
    private let appID: String
    private let baseURL: URL
    private let client: URLSessionHTTPClient
    init(appID: String = AppConfig.appID, baseURL: URL = AppConfig.baseURL, client: URLSessionHTTPClient) {
        self.appID = appID
        self.baseURL = baseURL
        self.client = client
    }
    
    func getCurrencies() async -> Result<RatesDTO, RemoteCurrenciesRepositoryError> {
        let path = "latest.json"
        let queryItems = [URLQueryItem(name: "app_id", value: appID)]
        let request = Request(baseURL: baseURL, path: path, queryItems: queryItems, method: .get)
        
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
