//
//  GetCurrenciesUseCase.swift
//  RateConverter
//
//  Created by 黃昭銘 on 2025/7/8.
//

import Foundation

/// **Error types for GetCurrenciesUseCase**
enum GetCurrenciesUseCaseError: Error {
    case failedToGetCurrencies
    case failedToSaveCurrencies
    case failedToSaveCurrenciesTimeStamp
}

/// **Protocol for fetching currency rates**
protocol GetCurrenciesUseCaseProtocol {
    func getLatestCurrencies() async throws -> [Rate]
    func getStoredCurrencyList() async throws -> [String]
}

class GetCurrenciesUseCase: GetCurrenciesUseCaseProtocol {
    let remoteRepository: RemoteCurrenciesRepositoryProtocol
    let storeRepository: StoreCurrenciesRepositoryProtocol
    private var latestRates: [Rate] = []
    
    init(remoteRepository: RemoteCurrenciesRepositoryProtocol, storeRepository: StoreCurrenciesRepositoryProtocol) {
        self.remoteRepository = remoteRepository
        self.storeRepository = storeRepository
    }
    
    func getLatestCurrencies() async throws -> [Rate] {
        let currentTimeStamp = Date().timeIntervalSince1970
        
        do {
            let lastFetchTime = try await storeRepository.getLastFetchTime()
            if isFetchNeeded(lastFetchTime: lastFetchTime, currentTimeStamp: currentTimeStamp) {
                let rates = try await fetchFromRemoteAndUpdateStore(currentTimeStamp: currentTimeStamp)
                latestRates = rates
                return rates
            } else {
                let rates = try await fetchFromLocal()
                latestRates = rates
                return rates
            }
        }  catch let error as GetCurrenciesUseCaseError {
            throw error
        } catch {
            throw GetCurrenciesUseCaseError.failedToGetCurrencies
        }
    }
    
    func getStoredCurrencyList() async throws -> [String] {
        if latestRates.isEmpty {
            latestRates = try await getLatestCurrencies()
        }
        return latestRates.map { $0.currency }.sorted()
    }
    
    
}

// MARK: - Private helpers
extension GetCurrenciesUseCase {
    // MARK: - Check if fetching is needed
    private func isFetchNeeded(lastFetchTime: TimeInterval, currentTimeStamp: TimeInterval) -> Bool {
        return (currentTimeStamp - lastFetchTime) > 1800 // Refresh if more than 30 minutes (1800 seconds) have passed
    }
    
    // MARK: - Fetch from remote and update local storage
    private func fetchFromRemoteAndUpdateStore(currentTimeStamp: TimeInterval) async throws -> [Rate] {
        let getCurrenciesResult = await remoteRepository.getCurrencies()
        
        switch getCurrenciesResult {
        case let .success(ratesDTO):
            do {
                try await storeRepository.saveLastFetchTime(timeStamp: currentTimeStamp)
            } catch {
                throw GetCurrenciesUseCaseError.failedToSaveCurrenciesTimeStamp
            }
            
            do {
                try await storeRepository.saveCurrencies(ratesDTO)
            } catch {
                throw GetCurrenciesUseCaseError.failedToSaveCurrencies
            }
            return ratesDTO.domainModels
            
        case .failure:
            throw GetCurrenciesUseCaseError.failedToGetCurrencies
        }
    }
    
    // MARK: - Fetch from local storage
    private func fetchFromLocal() async throws -> [Rate] {
        do {
            let ratesDTO = try await storeRepository.getCurrencies()
            return ratesDTO.domainModels
        } catch {
            throw GetCurrenciesUseCaseError.failedToGetCurrencies
        }
        
    }
}
