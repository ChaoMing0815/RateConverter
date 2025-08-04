//
//  ConverterViewModel.swift
//  RateConverter
//
//  Created by 黃昭銘 on 2025/7/18.
//

import Foundation

enum ConverterViewModelError: Error, Equatable {
    case unableToConvert(fromCurrency: String, toCurrency: String)
    case failedToFetchRates
    case unknownError
    
    var localizedDescription: String {
        switch self {
        case .unableToConvert(let from, let to):
            return "Unable to convert from \(from) to \(to) using available exchange rates."
        case .failedToFetchRates:
            return "Failed to fetch the latest exchange rates."
        case .unknownError:
            return "An unknown error occurred during conversion."
        }
    }
}

class ConverterViewModel {
    let getCurrenciesUseCase: GetCurrenciesUseCaseProtocol
    let convertCurrenciesUseCase: ConvertCurrenciesUseCaseProtocol
    
    var convertedAmountHandler: ((Float) -> Void)?
    var convertedResultHandler: (([(String, Float)]) -> Void)?
    var defaultCurrencySelectionHandler: ((Int) -> Void)?
    var errorHandler: ((String) -> Void)?
    var isLoadingHandler: ((Bool) -> Void)?
    
    var currencyList: [String] = []
    let defaultSelectedCurrency = "USD"
    lazy var selectedCurrency = defaultSelectedCurrency
    
    init(getCurrenciesUseCase: GetCurrenciesUseCaseProtocol, convertCurrenciesUseCase: ConvertCurrenciesUseCaseProtocol) {
        self.getCurrenciesUseCase = getCurrenciesUseCase
        self.convertCurrenciesUseCase = convertCurrenciesUseCase
    }
    
    // MARK: - Fetch latest exchange rates
    func fetchLatestCurrencies() async {
        do {
            isLoadingHandler?(true)
            let rates = try await getCurrenciesUseCase.getLatestCurrencies()
            currencyList = rates.map { $0.currency }.sorted()
            convertCurrenciesUseCase.updateRates(rates)
            isLoadingHandler?(false)
            
            defaultCurrencySelectionHandler?(currencyList.firstIndex(of: defaultSelectedCurrency) ?? 0)
        } catch {
            isLoadingHandler?(false)
            errorHandler?(ConverterViewModelError.failedToFetchRates.localizedDescription)
        }
    }
    
    // MARK: - Perform currency conversion
    func doConvertProcess(fromCurrency: String, toCurrency: String, amount: Float) async {
        do {
            isLoadingHandler?(true)
            
            if convertCurrenciesUseCase.rates.isEmpty {
                let latestRate = try await getCurrenciesUseCase.getLatestCurrencies()
                convertCurrenciesUseCase.updateRates(latestRate)
            }
            
            let converted = try convertCurrenciesUseCase.convert(fromCurrency, toCurrency: toCurrency, withAmount: amount)
            
            isLoadingHandler?(false)
            convertedAmountHandler?(converted)
        } catch let error as ConverterViewModelError {
            isLoadingHandler?(false)
            errorHandler?(error.localizedDescription)
        } catch _ as ConvertCurrenciesUseCaseError {
            isLoadingHandler?(false)
            errorHandler?(ConverterViewModelError.unableToConvert(fromCurrency: fromCurrency, toCurrency: toCurrency).localizedDescription)
        } catch {
            isLoadingHandler?(false)
            errorHandler?(ConverterViewModelError.unknownError.localizedDescription)
        }
    }
    
    // MARK: - Update conversion result for all currencies
    func updateConversionResult(amountText: String) {
        guard let amount = Float(amountText), amount > 0 else {
            convertedResultHandler?([])
            return
        }
        
        let results = convertCurrenciesUseCase.convertAllCurrencies(fromCurrency: selectedCurrency, amount: amount)
        convertedResultHandler?(results)
    }
    
    // MARK: - Update selected currency
    func setSelectedCurrency(_ currency: String) {
        selectedCurrency = currency
    }
}
