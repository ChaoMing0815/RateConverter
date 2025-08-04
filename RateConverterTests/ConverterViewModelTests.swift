//
//  ConverterViewModelTests.swift
//  RateConverterTests
//
//  Created by 黃昭銘 on 2025/8/2.
//

import XCTest
@testable import RateConverter

// MARK: - Mock GetCurrenciesUseCase
class MockGetCurrenciesUseCase: GetCurrenciesUseCaseProtocol {
    var stubbedRates: [Rate]? = nil
    var shouldThrowError = false
    
    func getLatestCurrencies() async throws -> [Rate] {
        if shouldThrowError {
            throw GetCurrenciesUseCaseError.failedToGetCurrencies
        }
        if let stub = stubbedRates {
            return stub
        } else {
            return []
        }
    }
    
    func getStoredCurrencyList() async throws -> [String] {
        if shouldThrowError {
            throw GetCurrenciesUseCaseError.failedToGetCurrencies
        }
        
        if let stub = stubbedRates {
            return stub.map { $0.currency }.sorted()
        } else {
            return []
        }
    }
}

// MARK: - Mock ConvertCurrenciesUseCase
class MockConvertCurrenciesUseCase: ConvertCurrenciesUseCaseProtocol {
    var rates: [Rate] = []
    var stubbedConvertedAmount: Float?
    var stubbedAllCurrenciesResults: [(String, Float)]?
    var shouldThrowError = false
    
    func updateRates(_ rates: [Rate]) {
        self.rates = rates
    }
    
    func convert(_ fromCurrency: String, toCurrency: String, withAmount amount: Float) throws -> Float {
        if shouldThrowError {
            throw ConvertCurrenciesUseCaseError.unableToConvert(fromCurrency: fromCurrency, toCurrency: toCurrency)
        }
        if let stub = stubbedConvertedAmount {
            return stub
        }
        
        guard let fromRate = rates.first(where: { $0.currency == fromCurrency })?.rate,
              let toRate = rates.first(where: { $0.currency == toCurrency })?.rate else {
            throw ConvertCurrenciesUseCaseError.unableToConvert(fromCurrency: fromCurrency, toCurrency: toCurrency)
        }
        return (amount / fromRate) * toRate
    }
    
    func convertAllCurrencies(fromCurrency: String, amount: Float) -> [(String, Float)] {
        if let stub = stubbedAllCurrenciesResults {
            return stub
        }
        
        guard let fromRate = rates.first(where: { $0.currency == fromCurrency })?.rate,
              fromRate > 0 else { return [] }
        
        return rates.map {
            let converted = (amount / fromRate ) * $0.rate
            return ($0.currency, converted)
        }
    }
}

// MARK: - ConverterViewModelTests
final class ConverterViewModelTests: XCTestCase {
    var viewModel: ConverterViewModel!
    
    var mockGetCurrenciesUseCase: MockGetCurrenciesUseCase!
    var mockConvertCurrenciesUseCase: MockConvertCurrenciesUseCase!
    
    override func setUp() {
        super.setUp()
        mockGetCurrenciesUseCase = MockGetCurrenciesUseCase()
        mockConvertCurrenciesUseCase = MockConvertCurrenciesUseCase()
        viewModel = ConverterViewModel(getCurrenciesUseCase: mockGetCurrenciesUseCase, convertCurrenciesUseCase: mockConvertCurrenciesUseCase)
    }
    
    override func tearDown() {
        mockGetCurrenciesUseCase = nil
        mockConvertCurrenciesUseCase = nil
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Test fetching latest currenies successfully
    func test_fetchLatestCurrencies_shouldUpdateCurrenciesList_andNotifyHandler() async  {
        let expectation = expectation(description: "Rates should be updated successfully.")
        
        mockGetCurrenciesUseCase.stubbedRates = [
            Rate(currency: "EUR", rate: 0.85),
            Rate(currency: "JPY", rate: 110.0),
            Rate(currency: "USD", rate: 1.0)
        ]
        
        viewModel.defaultCurrencySelectionHandler = { selectedIndex in
            let expectedSortedList = ["EUR", "JPY", "USD"]
            XCTAssertEqual(self.viewModel.currencyList, ["EUR" ,"JPY", "USD"], "Currency list should be sorted by A-Z order.")
            XCTAssertEqual(selectedIndex, expectedSortedList.firstIndex(of: "USD"), "USD should be selected as default currency.")
            
            expectation.fulfill()
        }
        
        await viewModel.fetchLatestCurrencies()
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    // MARK: - Test convert currencies successfully
    func test_doConvertProcess_returnConvertedAmount_andNotifyHandler() async {
        let expectation = expectation(description: "Should convert currency successfully")
        
        mockConvertCurrenciesUseCase.stubbedConvertedAmount =  85.0
        mockConvertCurrenciesUseCase.rates = [
            Rate(currency: "EUR", rate: 0.85),
            Rate(currency: "JPY", rate: 110.0),
            Rate(currency: "USD", rate: 1.0)
        ]
        
        var receivedAmount: Float?
        let expectedAmount: Float = 85.0
        
        viewModel.convertedAmountHandler = { convertedAmount in
            receivedAmount = convertedAmount
            expectation.fulfill()
        }
        
        await viewModel.doConvertProcess(fromCurrency: "USD", toCurrency: "EUR", amount: 100)
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        guard let receivedAmount = receivedAmount else {
            XCTFail("Expect converted amount but got nil")
            return
        }
        XCTAssertEqual(receivedAmount, expectedAmount, accuracy: 0.001, "Should convert 100 USD to 85 EUR")
    }
    
    func test_doConvertProcess_shouldFetchRates_whenRatesAreEmpty() async {
        let expectation = expectation(description: "Should fetch and convert when rates are empty")
        
        mockGetCurrenciesUseCase.stubbedRates = [
            Rate(currency: "EUR", rate: 0.85),
            Rate(currency: "USD", rate: 1.0),
            Rate(currency: "TWD", rate: 30.0)
        ]
        
        mockConvertCurrenciesUseCase.stubbedConvertedAmount = 85.0
        mockConvertCurrenciesUseCase.rates = []
        
        viewModel.convertedAmountHandler = { converted in
            XCTAssertEqual(converted, 85.0)
            expectation.fulfill()
        }
        
        await viewModel.doConvertProcess(fromCurrency: "USD", toCurrency: "EUR", amount: 100)
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    // MARK: - Test updating conversion results
    func test_updateConversionResult_shouldCallHandler_withExpectedResults() {
        let expectation = expectation(description: "convertedResultHandler shoud be called with result")
        
        mockConvertCurrenciesUseCase.rates = [
            Rate(currency: "USD", rate: 1.0),
            Rate(currency: "EUR", rate: 0.85),
            Rate(currency: "JPY", rate: 110.0)
        ]
        
        viewModel.setSelectedCurrency("USD")
        
        viewModel.convertedResultHandler = { result in
            XCTAssertEqual(result.count, 3)
            XCTAssertTrue(result.contains(where: { $0.0 == "EUR" }))
            expectation.fulfill()
        }
        
        viewModel.updateConversionResult(amountText: "100")
        wait(for: [expectation], timeout: 2.0)
    }
    
    func test_updateConversionResult_shouldReturnEmpty_whenInputIsInvalid() {
        let expectation = expectation(description: "Should return empty result for invalid input")
        
        viewModel.convertedResultHandler = { result in
            XCTAssertTrue(result.isEmpty)
            expectation.fulfill()
        }
        
        viewModel.updateConversionResult(amountText: "abc")
        wait(for: [expectation], timeout: 2.0)
    }
    
    func test_updateConversionResult_shouldReturnEmpty_whenAmountIsZero() {
        let expectation = expectation(description: "Should return empty result for 0 amount")
        
        viewModel.convertedResultHandler = { result in
            XCTAssertTrue(result.isEmpty)
            expectation.fulfill()
        }
        
        viewModel.updateConversionResult(amountText: "0")
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Test setting selected currency
    func test_setSelectedCurrency_shouldUpdateSelectedCurrency() {
        viewModel.setSelectedCurrency("EUR")
        XCTAssertEqual(viewModel.selectedCurrency, "EUR", "Selected currency should be updated")
    }
    
    // MARK: - Test error handling
    func test_fetchLatestCurrencies_throwError_whenFetchingFails() async {
        let expectation = expectation(description: "Error should be received when fetching rates fails ")
        
        mockGetCurrenciesUseCase.shouldThrowError = true
        
        viewModel.errorHandler = { error in
            XCTAssertEqual(error, ConverterViewModelError.failedToFetchRates.localizedDescription)
            expectation.fulfill()
        }
        
        await viewModel.fetchLatestCurrencies()
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func test_doConvertProcess_throwError_whenConversionFails() async {
        let expectation = expectation(description: "Error should be received during conversion")
        
        mockConvertCurrenciesUseCase.shouldThrowError = true
        
        viewModel.errorHandler = { error in
            XCTAssertEqual(error, ConverterViewModelError.unableToConvert(fromCurrency: "USD", toCurrency: "EUR").localizedDescription)
            expectation.fulfill()
        }
        
        await viewModel.doConvertProcess(fromCurrency: "USD", toCurrency: "EUR", amount: 100)
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    
}
