//
//  ConvertCurrenciesUseCaseTests.swift
//  RateConverterTests
//
//  Created by 黃昭銘 on 2025/7/31.
//

import XCTest
@testable import RateConverter

final class ConvertCurrenciesUseCaseTests: XCTestCase {
    var useCase: ConvertCurrenciesUseCase!
    
    override func setUp() {
        super.setUp()
        useCase = ConvertCurrenciesUseCase()
    }
    
    override func tearDown() {
        useCase = nil
        super.tearDown()
    }
    
    // MARK: - Test conversion
    /// Conversion should work correctly when exchange rate is available
    func test_convert_shouldReturnConvertedAmount_whenBaseUSDRateIsAvailable() throws {
        useCase.updateRates([
            Rate(currency: "USD", rate: 1.0),
            Rate(currency: "JPY", rate: 110.1),
            Rate(currency: "EUR", rate: 0.85)
        ])
        
        let convertedAmount = try useCase.convert("JPY", toCurrency: "EUR", withAmount: 4000)
        let expectedAmount: Float = ( 4000 / 110.1 ) * 0.85 // JPY -> USD -> EUR
        XCTAssertEqual(convertedAmount, expectedAmount, accuracy: 0.001, "JPY -> USD -> EUR conversion is correct")
    }
    
    /// Derictly return same amount when convert same currency
    func test_convert_sameCurrency_shouldReturnSameAmount() throws {
        useCase.updateRates([
            Rate(currency: "USD", rate: 1.0),
            Rate(currency: "JPY", rate: 110.1),
            Rate(currency: "EUR", rate: 0.85),
            Rate(currency: "TWD", rate: 29.3)
        ])
        
        let enterAmount: Float = 250
        let convertedAmount = try useCase.convert("TWD", toCurrency: "TWD", withAmount: enterAmount)
        let expectedAmount: Float = enterAmount
        XCTAssertEqual(convertedAmount, expectedAmount, accuracy: 0.001)
    }
    
    // MARK: - Test convert all currencies
    func test_convertAllCurrencies_shouldReturnExpectedResult() {
        useCase.updateRates([
            Rate(currency: "USD", rate: 1.0),
            Rate(currency: "JPY", rate: 110.0),
            Rate(currency: "EUR", rate: 0.85),
            Rate(currency: "TWD", rate: 30.0)
        ])
        
        let results = useCase.convertAllCurrencies(fromCurrency: "USD", amount: 200)
        let expected: [(String, Float)] = [
            ("USD", 200),
            ("EUR", 170),
            ("JPY", 22000),
            ("TWD", 6000)
        ]
        
        XCTAssertEqual(results.count, 4, "Should have 4 conversion results")
        
        for (currency, expectedAmount) in expected {
            guard let converted = results.first(where: { $0.0 == currency }) else {
                XCTFail("Missing converted currency: \(currency)")
                continue
            }
            XCTAssertEqual(converted.1, expectedAmount, accuracy: 0.01)
        }
    }
    
    func test_convertAllCurrencies_shouldReturnEmpty_whenAmountIsZero() {
        useCase.updateRates([
            Rate(currency: "USD", rate: 1.0),
            Rate(currency: "JPY", rate: 110.1),
            Rate(currency: "EUR", rate: 0.85)
        ])
        
        let results = useCase.convertAllCurrencies(fromCurrency: "JPY", amount: 0)
        XCTAssertTrue(results.isEmpty, "When amount = 0, should return an empty array")
    }
    
    func test_convertAllCurrencies_shouldReturnEmpty_whenRatesIsEmpty() {
        useCase.updateRates([])
        
        let results = useCase.convertAllCurrencies(fromCurrency: "JPY", amount: 1000)
        XCTAssertTrue(results.isEmpty, "When [Rates] is empty, should return an empty array")
    }
 
    // MARK: - Error handling
    /// Conversion fail or return nil when exchange rate is not available
    func test_convert_throwError_whenBaseUSDRateNotAvailable() throws {
        useCase.updateRates([
            Rate(currency: "USD", rate: 1.3),
            Rate(currency: "JPY", rate: 110.1),
            Rate(currency: "EUR", rate: 0.85)
        ])
        
        do {
            _ = try useCase.convert("JPY", toCurrency: "EUR", withAmount: 4000)
            XCTFail("Expected to throw ConvertCurrenciesUseCaseError but succeeded.")
        } catch let error as ConvertCurrenciesUseCaseError {
            XCTAssertEqual(error, .unableToConvert(fromCurrency: "JPY", toCurrency: "EUR"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_convert_throwError_whenRatesIsEmpty() throws {
        useCase.updateRates([])
        
        do {
            _ = try useCase.convert("USD", toCurrency: "EUR", withAmount: 300)
            XCTFail("Expected error but got success")
        } catch let error as ConvertCurrenciesUseCaseError {
            XCTAssertEqual(error, .unableToConvert(fromCurrency: "USD", toCurrency: "EUR"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_convert_throwError_whenFromCurrencyNotFound() throws {
        useCase.updateRates([
            Rate(currency: "USD", rate: 1.0),
            Rate(currency: "JPY", rate: 110.0)
        ])
        
        do {
            _ = try useCase.convert("ABC", toCurrency: "JPY", withAmount: 200)
            XCTFail("Expected error for missing fromCurrency but got success")
        } catch let error as ConvertCurrenciesUseCaseError {
            XCTAssertEqual(error, .unableToConvert(fromCurrency: "ABC", toCurrency: "JPY"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_convert_throwError_whenToCurrencyNotFound() throws {
        useCase.updateRates([
            Rate(currency: "USD", rate: 1.0),
            Rate(currency: "JPY", rate: 110.0)
        ])
        
        do {
            _ = try useCase.convert("JPY", toCurrency: "ZXC", withAmount: 200)
            XCTFail("Expected error for missing fromCurrency but got success")
        } catch let error as ConvertCurrenciesUseCaseError {
            XCTAssertEqual(error, .unableToConvert(fromCurrency: "JPY", toCurrency: "ZXC"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}

