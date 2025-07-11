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
