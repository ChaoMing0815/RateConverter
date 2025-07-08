//
//  RetriveCacheResult.swift
//  RateConverter
//
//  Created by 黃昭銘 on 2025/7/7.
//

import Foundation

public enum RetriveCacheResult {
    case empty
    case found(Any)
    case failure(Error)
}
