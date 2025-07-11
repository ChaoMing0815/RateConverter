//
//  RatesDTO.swift
//  RateConverter
//
//  Created by 黃昭銘 on 2025/7/9.
//

import Foundation

struct RatesDTO: Codable, Equatable {
    let rates: [String: Float]
    
    var domainModels: [Rate] {
        rates.map { .init(currency: $0.key, rate: $0.value) }
    }
}
