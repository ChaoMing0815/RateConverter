//
//  StoreCurrenciesRepository.swift
//  RateConverter
//
//  Created by 黃昭銘 on 2025/7/11.
//

import Foundation

enum StoreCurrenciesRepositoryError: Error {
    // Errors related to last fetch time
    case failedToSaveLastFetchTime
    case failedToGetLastFetchTime
    
    // Errors related to currency data
    case failedToSaveCurrencies
    case failedToGetCurrencies
    case cannotFindCurrencies
}

protocol StoreCurrenciesRepositoryProtocol {
    func saveLastFetchTime(timeStamp: TimeInterval) async throws
    func getLastFetchTime() async throws -> TimeInterval
    func saveCurrencies(_ rates: RatesDTO) async throws
    func getCurrencies() async throws -> RatesDTO
}

class StoreCurrenciesRepository: StoreCurrenciesRepositoryProtocol {
    private let store: ActorCodableCacheStoreWithExpiry
    private let lastFetchTimeKey = "last_fetch_time"
    private let currenciesKey = "currencies"
    
    init(store: ActorCodableCacheStoreWithExpiry) {
        self.store = store
    }

    // MARK: - Save Last Fetch Time
    func saveLastFetchTime(timeStamp: TimeInterval) async throws {
        do {
            try await store.insert(with: lastFetchTimeKey, json: "\(timeStamp)")
        } catch {
            throw StoreCurrenciesRepositoryError.failedToSaveLastFetchTime
        }
    }
    
    // MARK: - Retrieve Last Fetch Time
    func getLastFetchTime() async throws -> TimeInterval {
        let result = await store.retrieve(with: lastFetchTimeKey)
            switch result {
            case .empty:
                return TimeInterval.leastNormalMagnitude // Returns the smallest possible timestamp to force an update
            case let .found(json):
                guard let timeString = json as? String, let time  = Double(timeString) else {
                    throw StoreCurrenciesRepositoryError.failedToGetLastFetchTime
                }
                return time
            case .failure:
                throw StoreCurrenciesRepositoryError.failedToGetLastFetchTime
            }
        }

    
    // MARK: - Save Currency Data
    func saveCurrencies(_ rates: RatesDTO) async throws {
        do {
            let jsonData = try JSONEncoder().encode(rates)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw StoreCurrenciesRepositoryError.failedToSaveCurrencies
            }
            try await store.insert(with: currenciesKey, json: jsonString)
        } catch {
            throw StoreCurrenciesRepositoryError.failedToSaveCurrencies
        }
    }
    
    func getCurrencies() async throws -> RatesDTO {
        let result = await store.retrieve(with: currenciesKey)
        
        switch result {
        case .empty:
            throw StoreCurrenciesRepositoryError.cannotFindCurrencies
        case let .found(json):
            return try await parseRates(from: json)
        case .failure:
            throw StoreCurrenciesRepositoryError.failedToGetCurrencies
        }
    }
    
}

// MARK: - Private helpers
extension StoreCurrenciesRepository {
    /// Parses the retrieved currency exchange data into 'RaatesDTO'
    private func parseRates(from json: Any) async throws -> RatesDTO {
        let jsonData: Data
        
        if let jsonString = json as? String {
            guard let data = jsonString.data(using: .utf8) else {
                throw StoreCurrenciesRepositoryError.failedToGetCurrencies
            }
            jsonData = data
        } else if let jsonDict = json as? [String: Any] {
            jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
        } else {
            throw StoreCurrenciesRepositoryError.failedToGetCurrencies
        }
        
        return try JSONDecoder().decode(RatesDTO.self, from: jsonData)
    }
}
