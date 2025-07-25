//
//  AppConfig.swift
//  RateConverter
//
//  Created by 黃昭銘 on 2025/7/11.
//

import Foundation

enum AppConfig {
    static let baseURL = URL(string: "https://openexchangerates.org/api/")!
    static let appID = "9655c63914c648e58c1ed5f8c97c61f6"
    
    static let currenciesCacheFileName = "currencies_info.json"
    static let cacheExpiryInterval: TimeInterval = 60 * 60 // data will to be renew every hour
    
    static let defaultSelectedCurrency = "USD"
}
