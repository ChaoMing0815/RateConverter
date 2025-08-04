//
//  GetCurrenciesUseCaseTests.swift
//  RateConverterTests
//
//  Created by 黃昭銘 on 2025/7/28.
//

import XCTest
@testable import RateConverter

// MARK: - Mock remote repository
class MockRemoteCurrenciesRepository: RemoteCurrenciesRepositoryProtocol {
    var ratesResponse: Result<RatesDTO, RemoteCurrenciesRepositoryError> = .failure(.failedToGetLatestCurrencies)
    
    func getCurrencies() async -> Result<RatesDTO, RemoteCurrenciesRepositoryError> {
        return ratesResponse
    }
}

// MARK: - Mock store repository
class MockStoreCurrenciesRepository: StoreCurrenciesRepositoryProtocol {
    var lastFetchTime: TimeInterval?
    var storedRates: RatesDTO?
    var shouldThrowError = false
    
    func saveLastFetchTime(timeStamp: TimeInterval) async throws {
        if shouldThrowError { throw GetCurrenciesUseCaseError.failedToSaveCurrenciesTimeStamp }
        lastFetchTime = timeStamp
    }
    
    func getLastFetchTime() async throws -> TimeInterval {
        if shouldThrowError { throw GetCurrenciesUseCaseError.failedToGetCurrencies }
        guard let time = lastFetchTime else { throw GetCurrenciesUseCaseError.failedToGetCurrencies }
        return time
    }
    
    func saveCurrencies(_ rates: RateConverter.RatesDTO) async throws {
        if shouldThrowError { throw GetCurrenciesUseCaseError.failedToSaveCurrencies }
        storedRates = rates
    }
    
    func getCurrencies() async throws -> RateConverter.RatesDTO {
        if shouldThrowError { throw GetCurrenciesUseCaseError.failedToGetCurrencies }
        guard let rates = storedRates else { throw GetCurrenciesUseCaseError.failedToGetCurrencies }
        return rates
    }
}

final class GetCurrenciesUseCaseTests: XCTestCase {
    var useCase: GetCurrenciesUseCase!
    var mockRemoteRepository: MockRemoteCurrenciesRepository!
    var mockSotreRepository: MockStoreCurrenciesRepository!
    
    override func setUp() {
        super.setUp()
        mockRemoteRepository = MockRemoteCurrenciesRepository()
        mockSotreRepository = MockStoreCurrenciesRepository()
        useCase = GetCurrenciesUseCase(remoteRepository: mockRemoteRepository, storeRepository: mockSotreRepository)
    }
    
    override func tearDown() {
        useCase = nil
        mockRemoteRepository = nil
        mockSotreRepository = nil
        super.tearDown()
    }
    
    // MARK: - Test fetching from local storage when refresh is not needed
    /// Currencies should be fetch from local when the last fetch was within 30 minutes.
    func test_getCurrencies_fromLocal_whenFetchNotNeeded() async throws {
        let recentFetchTime = Date().timeIntervalSince1970 - 1000 // 16.67 minutes ago (< 30 minutes)
        mockSotreRepository.lastFetchTime = recentFetchTime
        let expectedRates = RatesDTO(rates: ["USD": 1.0])
        mockSotreRepository.storedRates = expectedRates
        
        let rates = try await useCase.getLatestCurrencies()
        XCTAssertEqual(rates, expectedRates.domainModels, "Should fetch exchange rates from local storage")
    }
    
    // MARK: - Test fetching from remote when refresh is needed
    /// Currencies should be fetch from local when the last fetch time was over 30 minutes.
    func test_getCurrencies_fromRemote_whenFetchNotNeeded() async throws {
        let oldFetchTime = Date().timeIntervalSince1970 - 4000 // 66.67 minutes ago (> 30 minutes)
        mockSotreRepository.lastFetchTime = oldFetchTime
        let expectedRates = RatesDTO(rates: ["USD": 1.2])
        mockRemoteRepository.ratesResponse = .success(expectedRates)
        
        let rates = try await useCase.getLatestCurrencies()
        
        XCTAssertEqual(rates, expectedRates.domainModels, "Should fetch exchagne rates from remote")
        XCTAssertEqual(mockSotreRepository.storedRates, expectedRates, "Should store new exchange rates data")
        XCTAssertEqual(mockSotreRepository.lastFetchTime!, Date().timeIntervalSince1970, accuracy: 0.01, "Should update the last fetch time")
    }
    
    // MARK: - Test error handler
    /// Should throw error when remote fetch fails
    func test_getCurrencies_throwError_whenRemoteFetchFails() async throws {
        let oldFetchTime = Date().timeIntervalSince1970 - 4000
        mockSotreRepository.lastFetchTime = oldFetchTime
        mockRemoteRepository.ratesResponse = .failure(.failedToGetLatestCurrencies)
        
        do {
            _ = try await useCase.getLatestCurrencies()
            XCTFail("Expected failedToGetCurrenciesError but got success")
        } catch let error as GetCurrenciesUseCaseError {
            XCTAssertEqual(error, .failedToGetCurrencies)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    /// Should throw error when local fetch fails
    func test_getCurrencies_throwError_whenLocalFetchFails() async throws {
        let recentFetchTime = Date().timeIntervalSince1970 - 1000
        mockSotreRepository.lastFetchTime = recentFetchTime
        mockSotreRepository.shouldThrowError = true
        
        do {
            _ = try await useCase.getLatestCurrencies()
            XCTFail("Expected failedToGetCurrenciesError but got success")
        } catch let error as GetCurrenciesUseCaseError {
            XCTAssertEqual(error, .failedToGetCurrencies)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    /// Should throw error when 'getLastFetchTime()' fails
    func test_getCurrencies_throwError_whenLastFetchTimeFails() async throws {
        mockSotreRepository.shouldThrowError = true
        
        do {
            _ = try await useCase.getLatestCurrencies()
            XCTFail("Expected failedToGetCurrenciesError but got success")
        } catch let error as GetCurrenciesUseCaseError {
            XCTAssertEqual(error, .failedToGetCurrencies)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    /// Should throw error when fetch from remote succeeds but'saveCurrencies()' fails
    func test_getCurrencies_throwError_whenSaveCurrenciesFails() async throws {
        let oldFetchTime = Date().timeIntervalSince1970 - 4000
        mockSotreRepository.lastFetchTime = oldFetchTime
        let expectedRates = RatesDTO(rates: ["USD": 1.2])
        mockRemoteRepository.ratesResponse = .success(expectedRates)
        mockSotreRepository.shouldThrowError = true
        
        do {
            _ = try await useCase.getLatestCurrencies()
            XCTFail("Expected failToSaveCurrencies error but got success")
        } catch let error as GetCurrenciesUseCaseError {
            XCTAssertEqual(error, .failedToSaveCurrencies)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
