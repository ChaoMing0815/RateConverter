//
//  ConvertCurrenciesUseCase.swift
//  RateConverter
//
//  Created by 黃昭銘 on 2025/7/16.
//

import Foundation

// Error types for ConvertCurrenciesUseCase
enum ConvertCurrenciesUseCaseError: Error {
    case unableToConvert(fromCurrency: String, toCurrency: String)
    
    var localizedDescription: String {
        switch self {
        case .unableToConvert(let from, let to):
            return "Unable to convert from \(from) to \(to) using available exchange rates."
        }
    }
}

protocol ConvertCurrenciesUseCaseProtocol {
    var rates: [Rate] { get }
    func updateRates(_ rates: [Rate])
    func convert(_ fromCurrency: String, toCurrency: String, withAmount amount: Float) throws -> Float
    func convertAllCurrencies(fromCurrency: String, amount: Float) -> [(String, Float)]
}

class ConvertCurrenciesUseCase: ConvertCurrenciesUseCaseProtocol {
    private(set) var rates: [Rate] = []
    
    func updateRates(_ rates: [Rate]) {
        self.rates = rates
    }
    
    func convert(_ fromCurrency: String, toCurrency: String, withAmount amount: Float) throws -> Float {
        guard !rates.isEmpty else {
            throw ConvertCurrenciesUseCaseError.unableToConvert(fromCurrency: fromCurrency, toCurrency: toCurrency)
        }
        
        guard let result = convertWithUSDBase(fromCurrency: fromCurrency, toCurrency: toCurrency, rates: rates, amount: amount) else {
            throw ConvertCurrenciesUseCaseError.unableToConvert(fromCurrency: fromCurrency, toCurrency: toCurrency)
        }
        
        return result
    }
    
    func convertAllCurrencies(fromCurrency: String, amount: Float) -> [(String, Float)] {
        guard amount > 0,
              !rates.isEmpty else { return [] } // Clear results if amount is zero
        
        return rates.compactMap { rate in
            guard let convertedAmount = convertWithUSDBase(fromCurrency: fromCurrency, toCurrency: rate.currency, rates: rates, amount: amount) else {
                return nil
            }
            return (rate.currency, convertedAmount)
        }
        
    }
}

// MARK: - Private helpers
extension ConvertCurrenciesUseCase {
    private func convertWithUSDBase(fromCurrency: String, toCurrency: String, rates: [Rate], amount: Float) -> Float? {
        let rateDict = Dictionary(uniqueKeysWithValues: rates.map { ($0.currency, $0.rate) })
        
        /// Use USD as default mediator convert rate
        guard let fromRate = rateDict[fromCurrency],
              let toRate = rateDict[toCurrency],
              let usdRate = rateDict["USD"],
              usdRate == 1.0 else {
            return nil
        }
        
        if fromCurrency == toCurrency { return amount }
        
        let amountInUSD = amount / fromRate
        let convertedAmount = amountInUSD * toRate
        
        return convertedAmount
    }
}

